#!/usr/bin/python3 -B
"""Fail closed on missing or one-way assurance traceability."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
BASELINE = ROOT / "assurance/requirements.json"
ID_PATTERN = re.compile(r"^JOP-[A-Z]+-[0-9]{3}$")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"FAIL: {message}")


def reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        require(key not in result, f"duplicate JSON key: {key}")
        result[key] = value
    return result


document = json.loads(
    BASELINE.read_text(encoding="utf-8"),
    object_pairs_hook=reject_duplicate_keys,
)
require(
    document.get("schema") == "jackal-omarchy-assurance-requirements-v1",
    "unsupported assurance-requirements schema",
)
require(
    document.get("product_claim", {}).get("status") == "not-established",
    "whole-product Platinum must remain unclaimed while mixed-language residuals exist",
)

requirements = document.get("requirements")
require(isinstance(requirements, list) and requirements, "requirements list is empty")
by_id: dict[str, dict[str, Any]] = {}

for requirement in requirements:
    require(isinstance(requirement, dict), "requirement is not an object")
    identifier = requirement.get("id")
    require(isinstance(identifier, str) and ID_PATTERN.fullmatch(identifier) is not None,
            f"invalid requirement id: {identifier!r}")
    require(identifier not in by_id, f"duplicate requirement id: {identifier}")
    by_id[identifier] = requirement
    shall = requirement.get("shall")
    require(isinstance(shall, str) and " shall " in f" {shall.lower()} ",
            f"requirement is not a shall-statement: {identifier}")
    require(requirement.get("status") in {"proved", "tested", "planned"},
            f"invalid requirement status: {identifier}")
    residuals = requirement.get("residuals")
    require(isinstance(residuals, list) and all(isinstance(item, str) for item in residuals),
            f"residual list is invalid: {identifier}")

    for relation in ("allocation", "verification"):
        paths = requirement.get(relation)
        require(isinstance(paths, list) and paths,
                f"{identifier} has no {relation} links")
        for raw_path in paths:
            require(isinstance(raw_path, str) and raw_path,
                    f"{identifier} has an invalid {relation} path")
            relative = Path(raw_path)
            require(not relative.is_absolute() and ".." not in relative.parts,
                    f"{identifier} {relation} escapes the repository: {raw_path}")
            path = (ROOT / relative).resolve()
            require(path.is_relative_to(ROOT),
                    f"{identifier} {relation} resolves outside the repository: {raw_path}")
            require(path.is_file() and not path.is_symlink(),
                    f"{identifier} {relation} is not a regular file: {raw_path}")
            text = path.read_text(encoding="utf-8")
            require(identifier in text,
                    f"{identifier} is not cited by its {relation} artifact: {raw_path}")

for claim in document.get("component_claims", []):
    require(claim.get("target") == "SPARK Platinum",
            "component target must name SPARK Platinum exactly")
    require(claim.get("status") in {"planned", "proved-local"},
            "component claim status is invalid")
    identifiers = claim.get("requirement_ids")
    require(isinstance(identifiers, list) and identifiers,
            "component claim has no allocated requirements")
    for identifier in identifiers:
        require(identifier in by_id, f"component claim cites unknown requirement: {identifier}")
        requirement = by_id[identifier]
        require(requirement.get("method") == "spark-platinum",
                f"component claim includes a non-SPARK requirement: {identifier}")
        if claim.get("status") == "proved-local":
            require(requirement.get("status") == "proved",
                    f"proved component includes an unproved requirement: {identifier}")
            require(requirement.get("residuals") == [],
                    f"proved component requirement carries an unresolved functional residual: {identifier}")

print("ASSURANCE_TRACEABILITY_PASS")
