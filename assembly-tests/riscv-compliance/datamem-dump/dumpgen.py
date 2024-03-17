from pathlib import Path
search_dir = Path('.')
flist = [x for x in search_dir.rglob('**/*') if x.is_file() and x.suffix.lower() == '.txt']
# dumpfile editor
#dump = open('o2_instmem.txt', 'r')
#mem = open('o2_instmem.mem', 'w')
limit = 4096
lines = 0
switch = False
entry = ''

p = Path("mem/")
p.mkdir(parents=True, exist_ok=True)

for f in flist:
    temp = (f.name).split('.')
    lines = 0    
    
    if len(temp) < 2:
        pass
    elif temp[1] == 'txt':
        dump = f.open()
        p = Path('./mem/' + temp[0]+ '.mem')
        mem = p.open('w')
        for line in dump:
            entry = line.strip('\n')
            mem.write(entry[6:8] + entry[4:6] + entry[2:4] + entry[0:2] + '\n')
            lines = lines + 1
        while (lines < limit):
            mem.write('00000000\n')
            lines = lines + 1
        dump.close()
        mem.close()

