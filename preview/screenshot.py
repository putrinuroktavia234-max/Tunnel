#!/usr/bin/env python3
"""Screenshot the 3 preview HTML files using Playwright headless chromium."""
import os
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE = Path(__file__).resolve().parent
OUT  = BASE / 'screenshots'
OUT.mkdir(exist_ok=True)

PAGES = [
    ('landing.html',   '01-landing.png',   1280, 900, True),
    ('dashboard.html', '02-dashboard.png', 1280, 900, True),
    ('admin.html',     '03-admin.png',     1280, 900, True),
]

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        for src, out, w, h, full in PAGES:
            ctx = browser.new_context(viewport={'width': w, 'height': h}, device_scale_factor=1.0)
            page = ctx.new_page()
            url = f'file://{BASE}/{src}'
            page.goto(url, wait_until='load')
            page.wait_for_timeout(700)
            out_path = OUT / out
            page.screenshot(path=str(out_path), full_page=full)
            print(f'OK  {out}  ({w}x{h}  full_page={full})')
            ctx.close()
        browser.close()

if __name__ == '__main__':
    main()