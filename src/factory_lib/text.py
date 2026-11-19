"""Text helpers."""

import re
import unicodedata

_NON_ALNUM = re.compile(r"[^a-z0-9]+")
_ELLIPSIS = "…"


def slugify(text: str) -> str:
    """Convert ``text`` to a lowercase, hyphen-separated, ASCII URL slug.

    >>> slugify("Hello, World!")
    'hello-world'
    """
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return _NON_ALNUM.sub("-", ascii_text.lower()).strip("-")


def truncate(text: str, max_len: int) -> str:
    """Shorten ``text`` to at most ``max_len`` characters, ending with '…' if cut.

    >>> truncate("Hello, World!", 8)
    'Hello, …'
    >>> truncate("Hi", 5)
    'Hi'
    """
    if max_len < 1:
        raise ValueError("max_len must be >= 1")
    if len(text) <= max_len:
        return text
    return text[: max_len - 1] + _ELLIPSIS
