#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python310Packages.beautifulsoup4 python310Packages.requests

from bs4 import BeautifulSoup
from urllib.parse import urlparse
from pathlib import Path
import requests, sys, subprocess, shutil, os

knock_path = Path(__file__).parent.parent.joinpath("result/bin/knock")
workspace = Path(__file__).parent.joinpath("workspace")

if workspace.exists():
    shutil.rmtree(workspace)
workspace.mkdir()

html = requests \
    .get("https://www.adobe.com/solutions/ebook/digital-editions/sample-ebook-library.html") \
    .text
soup = BeautifulSoup(html, 'html.parser')

links = []
for a_tag in soup.find_all('a'):
    if a_tag.string != "Download eBook":
        continue
    if not urlparse(a_tag.get("href")).path.endswith(".acsm"):
        continue
    
    links.append(a_tag.get("href"))

for i, link in enumerate(links):
    i = str(i)
    print("Testing URL #" + i + ":\n" + link)
    file = workspace.joinpath(i + ".acsm")

    r = requests.get(link)
    open(file, "wb").write(r.content)

    result = subprocess.run([knock_path, file])

    if result.returncode != 0:
        print("Failed")
        sys.exit()

    print("Success\n---")

print("All tests passed")
