"""Extract synthesis estimates and critical endpoints without treating them as STA."""
from pathlib import Path
import re,sys,html
p=Path(sys.argv[1]);s=p.read_text(errors='replace')
clean=lambda t:' '.join(html.unescape(re.sub('<[^>]+>',' ',t)).split())
a=s.find('<a name="performance">');b=s.find('<h3>Path&nbsp1',a)
print(clean(s[a:b]))
for m in re.finditer(r'<h3>Path&nbsp(\d+)</h3>(.*?)(?=<b>Data Arrival Path)',s,re.S):
 print('Path',m[1],clean(m[2]))
