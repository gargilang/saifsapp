from datetime import date, datetime
import unittest

from scripts.migration_r2 import (
    DateNormalizationError,
    NormalizedTimeline,
    date_candidates,
    normalize_timeline,
    validate_dataset,
)


class DateNormalizationTest(unittest.TestCase):
    def test_ambiguous_excel_date_has_stored_and_swapped_candidates(self):
        self.assertEqual(
            date_candidates(datetime(2021, 8, 1)),
            (date(2021, 8, 1), date(2021, 1, 8)),
        )

    def test_order_is_swapped_when_installments_would_precede_it(self):
        result = normalize_timeline(
            datetime(2021, 8, 1),
            [datetime(2021, 2, 24), datetime(2021, 3, 29)],
            cutoff=date(2026, 8, 24),
        )
        self.assertEqual(result.order, date(2021, 1, 8))
        self.assertEqual(result.payments, (date(2021, 2, 24), date(2021, 3, 29)))

    def test_late_ambiguous_installment_prefers_fewer_sequence_inversions(self):
        result = normalize_timeline(
            datetime(2020, 12, 30),
            [datetime(2021, 5, 31), datetime(2021, 1, 7)],
            cutoff=date(2026, 8, 24),
        )
        self.assertEqual(result.payments[-1], date(2021, 7, 1))

    def test_future_us_dates_offer_9_and_11_june_candidates(self):
        self.assertIn(date(2026, 6, 9), date_candidates(datetime(2026, 9, 6)))
        self.assertIn(date(2026, 6, 11), date_candidates(datetime(2026, 11, 6)))

    def test_payment_still_before_order_is_reported(self):
        result = normalize_timeline(
            datetime(2026, 8, 20),
            [datetime(2025, 12, 31)],
            cutoff=date(2026, 8, 24),
        )
        self.assertIn("payment_before_order", result.issues)

    def test_missing_date_raises_instead_of_using_january_fallback(self):
        with self.assertRaises(DateNormalizationError):
            normalize_timeline(None, [], cutoff=date(2026, 8, 24))

    def test_two_digit_indonesian_year_is_supported(self):
        self.assertEqual(
            date_candidates("30/1/21"),
            (date(2021, 1, 30),),
        )

    def test_successful_correction_is_not_counted_as_residual_warning(self):
        timeline = NormalizedTimeline(
            order=date(2021, 1, 8),
            payments=(date(2021, 2, 24),),
            corrections=(
                {
                    "field": "order",
                    "index": 0,
                    "raw": date(2021, 8, 1),
                    "normalized": date(2021, 1, 8),
                    "reason": "day_month_swap",
                },
            ),
        )
        report = validate_dataset([timeline], cutoff=date(2026, 8, 24))
        self.assertEqual(report.transactions_with_date_warnings, 0)

    def test_future_order_is_a_hard_validation_error(self):
        timeline = NormalizedTimeline(
            order=date(2026, 9, 1),
            payments=(),
            issues=("future_date",),
        )
        report = validate_dataset([timeline], cutoff=date(2026, 8, 24))
        self.assertFalse(report.ok)
        self.assertIn("future_order", report.errors[0])


if __name__ == "__main__":
    unittest.main()
