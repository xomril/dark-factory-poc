"""Text helpers."""

import re
import unicodedata

_NON_ALNUM = re.compile(r"[^a-z0-9]+")


def slugify(text: str) -> str:
    """Convert ``text`` to a lowercase, hyphen-separated, ASCII URL slug.

    >>> slugify("Hello, World!")
    'hello-world'
    """
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return _NON_ALNUM.sub("-", ascii_text.lower()).strip("-")
