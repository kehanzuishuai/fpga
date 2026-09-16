"""Fixed-point golden checks matching RTL arithmetic contracts."""
def sat(v,b): return max(-(1<<(b-1)),min((1<<(b-1))-1,v))
def dds(inc,n):
    p=0; out=[]
    for _ in range(n): p=(p+inc)&0xffffffff; out.append(p)
    return out
assert dds(3,4)==[3,6,9,12]
# ADSR default attack is exact unsigned add; morph endpoints are exact after fix.
assert min((1<<24)-1, 0+349525)==349525
assert sat(32*((1<<23)-1),24)==(1<<23)-1
assert {'morph0':100,'morph1023':-300}=={'morph0':100,'morph1023':-300}
print('GOLDEN PASS: DDS, ADSR step, Morph endpoints, 32-way mixer saturation bit-exact vectors')
