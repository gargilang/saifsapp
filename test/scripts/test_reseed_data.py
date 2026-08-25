from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from scripts.reseed_data import (
    BUSINESS_TABLES,
    SafetyError,
    backup_tables,
    build_reseed_payload,
    reconcile_remote,
    run_reseed,
)


ROOT = Path(__file__).resolve().parents[2]
PREVIEW = ROOT / "ref" / "PREVIEW_MIGRASI_R2.xlsx"


class FakeClient:
    def __init__(self, tables: dict[str, list[dict[str, object]]] | None = None):
        self.tables = tables or {}
        self.read_calls: list[str] = []
        self.write_calls: list[tuple[str, dict[str, object]]] = []

    def fetch_all(self, table: str) -> list[dict[str, object]]:
        self.read_calls.append(table)
        return self.tables.get(table, [])

    def rpc(self, name: str, payload: dict[str, object]) -> dict[str, object]:
        self.write_calls.append((name, payload))
        return {"ok": True}


class BrokenBackupClient(FakeClient):
    def fetch_all(self, table: str) -> list[dict[str, object]]:
        raise OSError(f"backup gagal pada {table}")


class ReseedSafetyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.payload = build_reseed_payload(PREVIEW)

    def test_default_mode_never_calls_network(self):
        client = FakeClient()

        result = run_reseed(PREVIEW, client=client, apply=False)

        self.assertEqual(client.read_calls, [])
        self.assertEqual(client.write_calls, [])
        self.assertEqual(result["mode"], "dry-run")

    def test_apply_requires_exact_confirmation_phrase(self):
        client = FakeClient()

        with self.assertRaises(SafetyError):
            run_reseed(PREVIEW, client=client, apply=True, confirmation="yes")

        self.assertEqual(client.read_calls, [])
        self.assertEqual(client.write_calls, [])

    def test_backup_failure_prevents_rpc_write(self):
        client = BrokenBackupClient()
        with tempfile.TemporaryDirectory() as temp_dir:
            with self.assertRaises(OSError):
                run_reseed(
                    PREVIEW,
                    client=client,
                    apply=True,
                    confirmation="RESET-BUSINESS-DATA",
                    backup_root=Path(temp_dir),
                )

        self.assertEqual(client.write_calls, [])

    def test_payload_has_control_counts_and_opening_balances(self):
        payload = self.payload

        self.assertEqual(len(payload["customers"]), 46)
        self.assertEqual(len(payload["purchases"]), 249)
        self.assertEqual(len(payload["payments"]), 1069)
        self.assertEqual(len(payload["fund_sources"]), 2)
        self.assertEqual(len(payload["fund_ledger_entries"]), 2)
        self.assertEqual(
            sum(row["jumlah_delta"] for row in payload["fund_ledger_entries"]),
            116_725_000,
        )
        self.assertEqual(payload["controls"]["harga_beli"], 877_769_000)
        self.assertEqual(payload["controls"]["harga_jual"], 971_417_500)
        self.assertEqual(payload["controls"]["payments_total"], 854_692_500)
        self.assertEqual(payload["controls"]["outstanding"], 116_725_000)

    def test_payload_is_deterministic_and_history_has_no_source(self):
        second = build_reseed_payload(PREVIEW)

        self.assertEqual(self.payload, second)
        self.assertTrue(all(row["fund_source_id"] is None for row in self.payload["purchases"]))
        self.assertTrue(all(row["fund_source_id"] is None for row in self.payload["payments"]))

    def test_backup_exports_every_business_table(self):
        tables = {table: [{"id": f"{table}-1"}] for table in BUSINESS_TABLES}
        client = FakeClient(tables)
        with tempfile.TemporaryDirectory() as temp_dir:
            output = backup_tables(client, Path(temp_dir), timestamp="20260825T010203Z")

            self.assertEqual(output.name, "reseed-20260825T010203Z")
            for table in BUSINESS_TABLES:
                path = output / f"{table}.json"
                self.assertTrue(path.exists())
                self.assertEqual(json.loads(path.read_text()), tables[table])

    def test_reconcile_accepts_payload_equivalent_remote_rows(self):
        tables = {
            table: list(self.payload.get(table, []))
            for table in BUSINESS_TABLES
        }
        client = FakeClient(tables)

        report = reconcile_remote(client, expected=self.payload)

        self.assertTrue(report["ok"])
        self.assertEqual(report["orphans"], 0)
        self.assertEqual(report["fund_balance_total"], 116_725_000)

    def test_reconcile_rejects_financial_mismatch(self):
        tables = {
            table: list(self.payload.get(table, []))
            for table in BUSINESS_TABLES
        }
        tables["payments"] = tables["payments"][:-1]

        with self.assertRaises(SafetyError):
            reconcile_remote(FakeClient(tables), expected=self.payload)

    def test_sql_rpc_is_service_role_only_and_preserves_users(self):
        sql = (ROOT / "supabase" / "migrations" / "0006_reseed_business_data.sql").read_text().lower()

        self.assertIn("security definer", sql)
        self.assertIn("grant execute on function public.reseed_business_data_v2(jsonb) to service_role", sql)
        self.assertIn("revoke all on function public.reseed_business_data_v2(jsonb) from authenticated", sql)
        self.assertNotIn("delete from public.profiles", sql)
        self.assertNotIn("delete from auth.users", sql)
        delete_order = [
            "delete from public.fund_ledger_entries",
            "delete from public.budget_entries",
            "delete from public.payments",
            "delete from public.purchases",
            "delete from public.customers",
            "delete from public.fund_sources",
        ]
        self.assertEqual([sql.index(statement) for statement in delete_order], sorted(sql.index(statement) for statement in delete_order))

    def test_safeupdate_fix_keeps_every_delete_scoped(self):
        sql = (ROOT / "supabase" / "migrations" / "0007_fix_reseed_safe_delete.sql").read_text().lower()

        for table in BUSINESS_TABLES:
            self.assertIn(f"delete from public.{table} where true;", sql)


if __name__ == "__main__":
    unittest.main()
