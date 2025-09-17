"""
Professional HTML/CSS CV Generator
Optimized for WeasyPrint (A4, no external assets)
"""
import os
os.add_dll_directory(r"D:\GTK3-Runtime Win64\bin")

from weasyprint import HTML, CSS  # import AFTER add_dll_directory

from typing import List, Iterable
from datetime import datetime
import tempfile
import re
import html as html_escape
from models import Profile, Achievement, Skill, Users
from flask import current_app

HEADING_RGB = "33, 37, 41"   # dark slate
ACCENT_RGB  = "25, 118, 210" # blue for section titles
INK_RGB     = "55, 65, 81"   # body text
MUTED_RGB   = "107, 114, 128"
RULE_RGB    = "229, 231, 235"
MONTH_FMT   = "%b %Y"        # e.g., "Jan 2024"

def _esc(s):
    return html_escape.escape(str(s)) if s is not None else ""

def _fmt_date(dt):
    return dt.strftime(MONTH_FMT) if dt else ""

def _linkify(text: str) -> str:
    """Turn raw URLs and emails into links (basic, safe for WeasyPrint)."""
    if not text:
        return ""
    # email
    text = re.sub(r'(?i)\b([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})\b',
                  r'<a href="mailto:\1">\1</a>', text, flags=re.I)
    # urls
    text = re.sub(r'(?i)\b((?:https?://)[^\s<]+)',
                  r'<a href="\1">\1</a>', text, flags=re.I)
    return text

class HTMLCVGenerator:
    def __init__(self):
        self.temp_dir = tempfile.mkdtemp()

    # ------------------------------
    # Public API
    # ------------------------------
    def generate_html(self, user: Users, profile: Profile,
                      achievements: List[Achievement],
                      skills: List[Skill]) -> str:
        # Group achievements
        education = [a for a in achievements if a.category == 'education']
        work      = [a for a in achievements if a.category in ('work', 'experience')]
        projects  = [a for a in achievements if a.category == 'project']
        awards    = [a for a in achievements if a.category == 'award']
        certs     = [a for a in achievements if a.category == 'certification']

        # Group skills
        tech = [s for s in skills if s.category in ('technical', 'tech', 'tools')]
        lang = [s for s in skills if s.category in ('language', 'languages')]
        soft = [s for s in skills if s.category in ('soft_skill', 'soft')]

        # Contact line with all profile links
        contacts = []
        if getattr(user, "phone", None):
            contacts.append(f'<a href="tel:{_esc(user.phone)}">{_esc(user.phone)}</a>')
        if getattr(user, "email", None):
            contacts.append(f'<a href="mailto:{_esc(user.email)}">{_esc(user.email)}</a>')
        
        if getattr(profile, "linkedin_url", None):
            linkedin_url = profile.linkedin_url if profile.linkedin_url.startswith(('http://', 'https://')) else f'https://{profile.linkedin_url}'
            contacts.append(f'<a href="{_esc(linkedin_url)}">LinkedIn</a>')
        if getattr(profile, "facebook_url", None):
            facebook_url = profile.facebook_url if profile.facebook_url.startswith(('http://', 'https://')) else f'https://{profile.facebook_url}'
            contacts.append(f'<a href="{_esc(facebook_url)}">Facebook</a>')
        if getattr(profile, "github_url", None):
            github_url = profile.github_url if profile.github_url.startswith(('http://', 'https://')) else f'https://{profile.github_url}'
            contacts.append(f'<a href="{_esc(github_url)}">GitHub</a>')
        if getattr(profile, "portfolio_url", None):
            portfolio_url = profile.portfolio_url if profile.portfolio_url.startswith(('http://', 'https://')) else f'https://{profile.portfolio_url}'
            contacts.append(f'<a href="{_esc(portfolio_url)}">Portfolio</a>')
        contact_line = " · ".join(contacts)

        summary_html = f'<p class="summary">{_linkify(_esc(profile.bio))}</p>' if getattr(profile, "bio", None) else ""

        parts: List[str] = []
        if work:      parts.append(self._section("Experience", work))
        if education: parts.append(self._section("Education", education))
        if projects:  parts.append(self._section("Projects", projects))
        if awards:    parts.append(self._section("Awards", awards))
        if certs:     parts.append(self._section("Certifications", certs))

        skills_html = self._skills_section(tech, lang, soft)
        if skills_html:
            parts.append(skills_html)

        return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>CV – {_esc(user.name)}</title>
<style>
/* -------- Page & Typography -------- */
@page {{
  size: A4;
  margin: 20mm 18mm 20mm 18mm;
}}
:root {{
  --ink: rgb({INK_RGB});
  --muted: rgb({MUTED_RGB});
  --heading: rgb({HEADING_RGB});
  --accent: rgb({ACCENT_RGB});
  --rule: rgb({RULE_RGB});
}}
* {{
  box-sizing: border-box;
}}
html, body {{
  padding: 0; margin: 0;
}}
body {{
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue",
               Arial, "Noto Sans", "Liberation Sans", sans-serif;
  color: var(--ink);
  font-size: 12pt;
  line-height: 1.45;
}}
a {{ color: inherit; text-decoration: none; border-bottom: 0.75pt solid rgba(25,118,210,0.35); }}
h1,h2,h3,p,ul {{ margin: 0; padding: 0; }}

.wrapper {{
  display: block;
}}

.header {{
  text-align: center;
  margin-bottom: 10mm;
}}
.name {{
  font-weight: 700;
  font-size: 18pt;
  letter-spacing: 0.2pt;
  color: var(--heading);
}}
.tagline {{
  margin-top: 2mm;
  color: var(--muted);
  font-size: 10pt;
}}
.contact {{
  margin-top: 2mm;
  font-size: 9.5pt;
  color: var(--muted);
}}

.summary {{
  margin-top: 4mm;
  text-align: left;
}}

.rule {{
  height: 1px;
  background: var(--rule);
  margin: 6mm 0 2mm 0;
}}

.section {{
  margin-top: 6mm;
}}
.section-title {{
  font-weight: 700;
  font-size: 11pt;
  color: var(--accent);
  letter-spacing: 0.3pt;
  text-transform: uppercase;
  margin-bottom: 2.5mm;
}}

.entry {{
  margin-bottom: 4.5mm;
}}
.entry-head {{
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 6mm;
}}
.entry-left {{
  min-width: 0;
}}
.role {{
  font-weight: 600;
  font-size: 10.5pt;
  color: var(--heading);
}}
.org {{
  color: var(--muted);
  font-size: 9.8pt;
}}
.place {{
  color: var(--muted);
  font-size: 9.3pt;
}}
.dates {{
  flex: 0 0 auto;
  white-space: nowrap;
  color: var(--muted);
  font-size: 9.5pt;
}}
.entry-meta {{
  margin-top: 0.75mm;
  color: var(--muted);
  font-size: 9.3pt;
}}

.entry-bullets {{
  margin-top: 2mm;
  padding-left: 4.8mm;
}}
.entry-bullets li {{
  margin: 1.2mm 0;
}}
.small {{
  font-size: 9pt;
  color: var(--muted);
  text-align: center;
  margin-top: 8mm;
}}

/* Avoid breaking headings from first entry line */
.section, .entry, .entry-head, .entry-bullets {{
  page-break-inside: avoid;
}}

</style>
</head>
<body>
  <main class="wrapper">
    <header class="header">
      <div class="name">{_esc(user.name)}</div>
      {f'<div class="tagline">{_esc(getattr(profile, "title", "")).strip()}</div>' if getattr(profile, "title", None) else ""}
      <div class="contact">{contact_line}</div>
      {summary_html}
    </header>

    <div class="rule"></div>

    {''.join(parts)}

    <div class="small">Generated on {datetime.now().strftime('%B %d, %Y')}</div>
  </main>
</body>
</html>"""

    # ------------------------------
    # Sections & entries
    # ------------------------------
    def _section(self, title: str, items: Iterable[Achievement]) -> str:
        entries = [self._entry(i) for i in items if i]
        if not any(entries):
            return ""
        return f"""
<section class="section">
  <div class="section-title">{_esc(title)}</div>
  {''.join(entries)}
</section>
"""

    def _entry(self, item: Achievement) -> str:
        # Dates
        start = _fmt_date(getattr(item, "start_date", None))
        if getattr(item, "is_current", False):
            end = "Present"
        else:
            end = _fmt_date(getattr(item, "end_date", None))
        date_str = f"{start} – {end}" if start or end else ""

        # Title / Org / Place
        title = _esc(getattr(item, "title", "") or getattr(item, "role", "") or getattr(item, "name", ""))
        org   = _esc(getattr(item, "organization", "") or getattr(item, "company", "") or getattr(item, "issuer", ""))
        place = _esc(getattr(item, "location", ""))

        # Secondary meta (e.g., GPA, grade)
        meta_pieces = []
        if getattr(item, "grade_or_result", None):
            meta_pieces.append(f"GPA: {_esc(item.grade_or_result)}")
        if getattr(item, "skills_learned", None):
            meta_pieces.append(_esc(item.skills_learned))
        meta_html = f'<div class="entry-meta">{ " · ".join(meta_pieces) }</div>' if meta_pieces else ""

        bullets = self._normalize_bullets(getattr(item, "description", "") or getattr(item, "details", ""))
        bullets_html = f"<ul class='entry-bullets'>{''.join(f'<li>{_linkify(_esc(b))}</li>' for b in bullets)}</ul>" if bullets else ""

        left_top = " · ".join([p for p in [f"<span class='role'>{title}</span>" if title else "",
                                           f"<span class='org'>{org}</span>" if org else ""] if p])
        left_bottom = f"<span class='place'>{place}</span>" if place else ""

        return f"""
<article class="entry">
  <div class="entry-head">
    <div class="entry-left">
      <div>{left_top}</div>
      {left_bottom}
    </div>
    {f"<div class='dates'>{_esc(date_str)}</div>" if date_str else ""}
  </div>
  {meta_html}
  {bullets_html}
</article>
"""

    # ------------------------------
    # Skills
    # ------------------------------
    def _skills_section(self, tech: List[Skill], lang: List[Skill], soft: List[Skill]) -> str:
        def line(items: List[Skill]) -> str:
            if not items:
                return ""
            # Each Skill has .name and optional .level
            parts = []
            for s in items:
                label = _esc(getattr(s, "name", ""))
                level = _esc(getattr(s, "level", "") or getattr(s, "proficiency", ""))
                parts.append(f"{label}{f' ({level})' if level else ''}")
            return " · ".join(p for p in parts if p)

        rows = []
        if tech: rows.append(f"<div><strong>Technical:</strong> {line(tech)}</div>")
        if lang: rows.append(f"<div><strong>Languages:</strong> {line(lang)}</div>")
        if soft: rows.append(f"<div><strong>Soft Skills:</strong> {line(soft)}</div>")

        if not rows:
            return ""

        return f"""
<section class="section">
  <div class="section-title">Skills</div>
  <div class="skills">
    {' '.join(rows)}
  </div>
</section>
"""

    # ------------------------------
    # Bullet normalization
    # ------------------------------
    def _normalize_bullets(self, text: str) -> List[str]:
        """
        Accepts free-form description and returns clean bullet strings.
        - Splits on newlines or " - " / " • " / "*" prefixes
        - Strips numbering
        - Drops empty lines
        """
        if not text:
            return []
        raw = []
        for line in text.splitlines():
            line = line.strip()
            line = re.sub(r"^\s*([-\u2022*]|\d+\.)\s+", "", line)  # -, •, *, 1.
            if line:
                raw.append(line)
        # Also split on explicit separators inside long paragraphs
        joined = " | ".join(raw)
        parts = [p.strip() for p in re.split(r"\s+\|\s+| \u2022 ", joined) if p.strip()]
        # Keep bullets shortish
        clean = []
        for p in parts:
            p = re.sub(r"\s+", " ", p).strip()
            if p:
                clean.append(p)
        return clean
