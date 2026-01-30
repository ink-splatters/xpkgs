#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["requests"]
# ///

import json
import logging
import re
import sys
from dataclasses import asdict, dataclass, field
from enum import StrEnum, auto
from typing import Any

import requests


class Arch(StrEnum):
    ARM64 = auto()
    X86_64 = auto()


@dataclass(frozen=True, slots=True)
class MetaInfo:
    arch: Arch
    sha256: str
    version: str
    url: str
    details: dict[str, Any] = field(default_factory=dict)


URL = "https://api.github.com/repos/ungoogled-software/ungoogled-chromium-macos/releases/latest"
arch = Arch.ARM64

logging.basicConfig(stream=sys.stderr, level=logging.INFO)
logger = logging.getLogger("fetch-meta")


def asset_for_arch(assets: list[dict[str, Any]], *, arch: Arch) -> dict[str, Any] | None:
    r = re.compile(r"ungoogled-chromium_[0-9.-]+_(.+)-macos.dmg")

    def arch_from_name(name: str) -> Arch | None:
        m = re.match(r, name)
        return None if m is None else Arch(m.group(1))

    for ax in assets:
        name = ax["name"]
        if arch_from_name(name) == arch:
            return ax

    return None


def filter_dict(d: dict[str, Any], *, keys: set[str]) -> dict[str, Any]:
    return {k: d[k] for k in d if k in keys}


def parse(data: dict[str, Any]) -> MetaInfo:
    ax = asset_for_arch(data["assets"], arch=arch)

    if ax is None:
        raise ValueError(f"no assets were found for arch: {arch}")

    details: dict[str, Any] = filter_dict(
        data, keys={"tag_name", "prerelease", "published_at"}
    ) | filter_dict(ax, keys={"size", "digest", "created_at", "updated_at", "browser_download_url"})

    return MetaInfo(
        arch=arch,
        version=data["tag_name"],
        sha256=ax["digest"][7:],
        url=ax["browser_download_url"],
        details=details,
    )


def fetch(url: str) -> dict[str, str]:
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    html = requests.get(url, headers=headers)
    html.raise_for_status()

    return html.json()


if __name__ == "__main__":
    try:
        logger.info("Fetching latest release info...")

        data = fetch(URL)
        info = parse(data)

        print(json.dumps(asdict(info), indent=2))
    except Exception as e:
        logger.error(str(e))
        raise SystemExit() from e
