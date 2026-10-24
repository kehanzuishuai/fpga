"""Split fixed rounded-mask geometry across existing scene stages13/14."""
import re

def retime_wells(s):
    if 'logic [12:0] well_corner_0;' in s:return s
    a=s.index(' begin:STAGE_13 ');b=s.index(' begin:STAGE_14 ',a);c=s.index(' begin:STAGE_15 ',b)
    previous=s[a:b];current=s[b:c]
    pattern=r'd\.(well_hits|sound_hits)\[(\d+)\]=rounded\(d.sx,d.sy,([^;]+)\);'
    shapes=re.findall(pattern,current);assert len(shapes)==12
    fields=[];prep=[]
    for kind,i,parameters in shapes:
        name=('well' if kind=='well_hits' else 'sound')+'_corner_'+i
        radius=int(parameters.split(',')[-1])
        fields.append(f'  logic [12:0] {name};')
        prep.append(f'd.{name}=round_geometry(d.sx,d.sy,{parameters});')
        original=f'd.{kind}[{i}]=rounded(d.sx,d.sy,{parameters});'
        current=current.replace(original,f"d.{kind}[{i}]=round_finish(d.{name},6'd{radius});",1)
    marker='   d=incoming;';assert previous.count(marker)==1
    previous=previous.replace(marker,marker+'\nif(MATERIAL_SAMPLE==0)begin\n'+'\n'.join(prep)+'\nend',1)
    s=s[:a]+previous+current+s[c:]
    marker='  logic [6:0] well_hits;';assert s.count(marker)==1
    return s.replace(marker,'\n'.join(fields)+'\n'+marker,1)
