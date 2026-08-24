"""Pure helpers for normalizing dates in the r2 migration workbook.

The workbook was entered with an Indonesian ``dd/mm/yyyy`` intent, while
Excel may have stored an ambiguous value using the US interpretation.  Date
normalization therefore keeps both interpretations where possible and picks
the deterministic path with the fewest chronology problems.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, time
from itertools import product
from typing import Any, Iterable, Mapping, Sequence

try:
    from openpyxl.utils.datetime import from_excel
except ImportError:  # pragma: no cover - openpyxl is supplied by the migration env
    from_excel = None


class DateNormalizationError(ValueError):
    """Raised when a required workbook date cannot be interpreted."""


def _coerce_string(value: str) -> date:
    value = value.strip()
    if not value:
        raise DateNormalizationError("empty date value")

    # An explicit slash-separated value is the client's intended Indonesian
    # format.  ISO values are accepted for generated previews and cutoffs.
    for fmt in (
        "%d/%m/%Y",
        "%d/%m/%y",
        "%d-%m-%Y",
        "%d-%m-%y",
        "%Y/%m/%d",
        "%Y-%m-%d",
    ):
        try:
            return datetime.strptime(value, fmt).date()
        except ValueError:
            continue
    try:
        return datetime.fromisoformat(value).date()
    except ValueError as exc:
        raise DateNormalizationError(f"invalid date value: {value!r}") from exc


def coerce_excel_date(value: object) -> date:
    """Convert an openpyxl/Excel date value to a ``date``.

    No placeholder date is produced for null or malformed values.  Numeric
    values are interpreted as Excel serials using openpyxl's epoch handling.
    """

    if value is None or isinstance(value, bool):
        raise DateNormalizationError("missing date value")
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    if isinstance(value, str):
        return _coerce_string(value)
    if isinstance(value, (int, float)):
        if from_excel is None:
            raise DateNormalizationError("openpyxl is required for Excel serial dates")
        try:
            converted = from_excel(value)
        except (TypeError, ValueError, OverflowError) as exc:
            raise DateNormalizationError(f"invalid Excel serial date: {value!r}") from exc
        if isinstance(converted, datetime):
            return converted.date()
        if isinstance(converted, date):
            return converted
        if isinstance(converted, time):
            raise DateNormalizationError(f"Excel serial has no date: {value!r}")
    raise DateNormalizationError(f"unsupported date value: {value!r}")


def date_candidates(value: object) -> tuple[date, ...]:
    """Return stored and, when valid, day/month-swapped date candidates."""

    stored = coerce_excel_date(value)
    candidates = [stored]
    if stored.day <= 12 and stored.month <= 12 and stored.day != stored.month:
        swapped = date(stored.year, stored.day, stored.month)
        candidates.append(swapped)
    return tuple(dict.fromkeys(candidates))


def _pairwise(values: Sequence[date]) -> Iterable[tuple[date, date]]:
    return zip(values, values[1:])


def _score(path: tuple[date, ...], raw: tuple[date, ...], cutoff: date) -> tuple[int, int, int, int, tuple[date, ...]]:
    purchase_date, *payment_dates = path
    future = sum(value > cutoff for value in path)
    before_order = sum(value < purchase_date for value in payment_dates)
    inversions = sum(a > b for a, b in _pairwise(payment_dates))
    swaps = sum(chosen != original for chosen, original in zip(path, raw))
    return future, before_order, inversions, swaps, path


def _issue_names(metrics: tuple[int, int, int, int]) -> tuple[str, ...]:
    future, before_order, inversions, _swaps = metrics
    issues: list[str] = []
    if future:
        issues.append("future_date")
    if before_order:
        issues.append("payment_before_order")
    if inversions:
        issues.append("payment_sequence_inversion")
    return tuple(issues)


def _correction_entries(raw: tuple[date, ...], chosen: tuple[date, ...]) -> tuple[dict[str, Any], ...]:
    corrections: list[dict[str, Any]] = []
    for index, (original, normalized) in enumerate(zip(raw, chosen)):
        if original == normalized:
            continue
        field = "order" if index == 0 else "payment"
        corrections.append(
            {
                "field": field,
                "index": index,
                "raw": original,
                "normalized": normalized,
                "reason": "day_month_swap",
            }
        )
    return tuple(corrections)


@dataclass(frozen=True)
class TimelineCandidate:
    """One candidate path retained for the validation sheet."""

    path: tuple[date, ...]
    score: tuple[int, int, int, int]
    reasons: tuple[str, ...]


@dataclass(frozen=True)
class NormalizedTimeline:
    """Selected timeline plus all evidence used to select it."""

    order: date
    payments: tuple[date, ...]
    issues: tuple[str, ...] = ()
    corrections: tuple[dict[str, Any], ...] = ()
    raw: tuple[date, ...] = ()
    candidates: tuple[tuple[date, ...], ...] = ()
    scores: tuple[tuple[int, int, int, int], ...] = ()
    candidate_details: tuple[TimelineCandidate, ...] = ()
    selected_score: tuple[int, int, int, int] = ()

    @property
    def candidate_paths(self) -> tuple[tuple[date, ...], ...]:
        return self.candidates

    @property
    def candidate_scores(self) -> tuple[tuple[int, int, int, int], ...]:
        return self.scores

    @property
    def correction_reasons(self) -> tuple[str, ...]:
        return tuple(entry["reason"] for entry in self.corrections)


def normalize_timeline(order: object, payments: Iterable[object], cutoff: object) -> NormalizedTimeline:
    """Choose a date interpretation using chronology-first deterministic scoring."""

    try:
        payment_values = tuple(payments)
    except TypeError as exc:
        raise DateNormalizationError("payments must be iterable") from exc

    raw = (coerce_excel_date(order), *(coerce_excel_date(payment) for payment in payment_values))
    cutoff_date = coerce_excel_date(cutoff)
    candidate_sets = (date_candidates(order), *(date_candidates(payment) for payment in payment_values))
    paths = tuple(product(*candidate_sets))

    scored = tuple((_score(path, raw, cutoff_date), path) for path in paths)
    chosen_score_with_path, chosen = min(scored, key=lambda item: item[0])
    selected_metrics = chosen_score_with_path[:4]
    details = tuple(
        TimelineCandidate(path=path, score=score[:4], reasons=_issue_names(score[:4]))
        for score, path in scored
    )
    return NormalizedTimeline(
        order=chosen[0],
        payments=tuple(chosen[1:]),
        issues=_issue_names(selected_metrics),
        corrections=_correction_entries(raw, chosen),
        raw=raw,
        candidates=tuple(path for path in paths),
        scores=tuple(score[:4] for score, _path in scored),
        candidate_details=details,
        selected_score=selected_metrics,
    )


@dataclass(frozen=True)
class ValidationReport:
    """Date-focused validation output used by preview generation."""

    ok: bool
    errors: tuple[str, ...] = ()
    warnings: tuple[str, ...] = ()
    issues: tuple[str, ...] = ()
    future_payment_count: int = 0
    payment_before_order_count: int = 0
    transactions_with_date_warnings: int = 0
    summary: str = ""


def _dataset_timelines(dataset: object) -> tuple[object, ...]:
    if isinstance(dataset, Mapping):
        for key in ("timelines", "transactions"):
            if key in dataset:
                return tuple(dataset[key])
        return ()
    for key in ("timelines", "transactions"):
        value = getattr(dataset, key, None)
        if value is not None:
            return tuple(value)
    if isinstance(dataset, Iterable) and not isinstance(dataset, (str, bytes)):
        return tuple(dataset)
    return ()


def _timeline_from_row(row: object) -> NormalizedTimeline | None:
    if isinstance(row, NormalizedTimeline):
        return row
    if isinstance(row, Mapping):
        candidate = row.get("timeline")
        if isinstance(candidate, NormalizedTimeline):
            return candidate
        order = row.get("order", row.get("tanggal"))
        payments = row.get("payments", ())
    else:
        candidate = getattr(row, "timeline", None)
        if isinstance(candidate, NormalizedTimeline):
            return candidate
        order = getattr(row, "order", getattr(row, "tanggal", None))
        payments = getattr(row, "payments", ())
    if isinstance(order, date) and all(isinstance(payment, date) for payment in payments):
        payment_dates = tuple(payments)
        before = sum(payment < order for payment in payment_dates)
        inversions = sum(a > b for a, b in _pairwise(payment_dates))
        issues = tuple(
            name
            for name, count in (
                ("payment_before_order", before),
                ("payment_sequence_inversion", inversions),
            )
            if count
        )
        return NormalizedTimeline(order=order, payments=payment_dates, issues=issues)
    return None


def validate_dataset(dataset: object, cutoff: object = date.today()) -> ValidationReport:
    """Aggregate date anomalies without hiding residual chronology problems.

    Chronology warnings remain visible in ``warnings``/``issues``.  Future
    dates are hard errors because they cannot be imported as-is.  The function
    accepts either a collection of ``NormalizedTimeline`` values or a dataset
    exposing a ``timelines``/``transactions`` collection.
    """

    cutoff_date = coerce_excel_date(cutoff)
    timelines = tuple(timeline for row in _dataset_timelines(dataset) if (timeline := _timeline_from_row(row)) is not None)
    errors: list[str] = []
    warnings: list[str] = []
    issue_names: list[str] = []
    future_payment_count = 0
    payment_before_order_count = 0
    transactions_with_date_warnings = 0

    for index, timeline in enumerate(timelines, start=1):
        future_order = timeline.order > cutoff_date
        future_payments = sum(payment > cutoff_date for payment in timeline.payments)
        before_order = sum(payment < timeline.order for payment in timeline.payments)
        future_payment_count += future_payments
        payment_before_order_count += before_order
        if timeline.issues or future_order or future_payments or before_order:
            transactions_with_date_warnings += 1
        if future_order:
            errors.append(f"timeline {index}: future_order")
        if future_payments:
            errors.append(f"timeline {index}: future_payment ({future_payments})")
        for issue in timeline.issues:
            if issue not in issue_names:
                issue_names.append(issue)
            if issue != "future_date":
                warnings.append(f"timeline {index}: {issue}")

    summary = (
        f"{'VALID' if not errors else 'INVALID'}: "
        f"{len(timelines)} timeline(s), "
        f"{future_payment_count} future payment(s), "
        f"{payment_before_order_count} payment(s) before order"
    )
    return ValidationReport(
        ok=not errors,
        errors=tuple(errors),
        warnings=tuple(warnings),
        issues=tuple(issue_names),
        future_payment_count=future_payment_count,
        payment_before_order_count=payment_before_order_count,
        transactions_with_date_warnings=transactions_with_date_warnings,
        summary=summary,
    )


__all__ = [
    "DateNormalizationError",
    "NormalizedTimeline",
    "TimelineCandidate",
    "ValidationReport",
    "coerce_excel_date",
    "date_candidates",
    "normalize_timeline",
    "validate_dataset",
]
