import subprocess,re,html,json,difflib,sys
BASE='b8e1813^'; HEAD='HEAD'  # после отката 384/390 (26.10) их изменений нет
pages={'374':'374/block-9242','382':'382/block-9274','384':'384/block-9282','390':'390/block-9294','392':'392/block-9298','394':'394/block-9302','396':'396/block-9306'}
def text(rev,p):
    s=subprocess.run(['git','show',f'{rev}:landing/site78/{p}.public.html'],capture_output=True,text=True).stdout
    s=re.sub(r'<(script|style)[^>]*>.*?</\1>','',s,flags=re.S|re.I)
    s=re.sub(r'<\s*(br|/p|/div|/li|/h\d)\s*/?>','\n',s,flags=re.I)
    s=re.sub(r'<[^>]+>','',s); s=html.unescape(s).replace('\xa0',' ')
    s=re.sub(r'[ \t]+',' ',s)
    lines=[l.strip() for l in s.split('\n') if l.strip()]
    # join wrapped lines into clauses: new clause starts with number or heading
    out=[]
    for l in lines:
        if out and not re.match(r'^(\d+[\.\dA]*\s|[0-9]+\.[0-9]|[А-ЯЁ ]{6,}$|[а-я]\)|–|-|\(|Редакция|Настоящ)',l):
            out[-1]+=' '+l
        else: out.append(l)
    return out
res={}
for lid,p in pages.items():
    a=text(BASE,p); b=text(HEAD,p)
    sm=difflib.SequenceMatcher(a=a,b=b,autojunk=False)
    ch=[]
    for op,i1,i2,j1,j2 in sm.get_opcodes():
        if op=='equal': continue
        ch.append({'op':op,'old':a[i1:i2],'new':b[j1:j2]})
    res[lid]=ch
    print(lid,'changes',len(ch))
json.dump(res,open(sys.argv[1],'w',encoding='utf-8'),ensure_ascii=False,indent=1)
