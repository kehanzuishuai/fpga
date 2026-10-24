"""Permit reuse only for stricter min-delay/report changes, keeping clocks fixed."""
def verify_stricter_sdc(before,after):
    def split(s):
        ordinary=[];minimum={};reports=[]
        for line in s.splitlines():
            t=' '.join(line.split())
            if not t or t.startswith('#'):continue
            if t.startswith('set_min_delay '):
                command,value=t.rsplit(' ',1);number=float(value)
                assert 0<number<=2,('Expected positive bounded min delay',t)
                assert command not in minimum,('Duplicate minimum target',command)
                minimum[command]=number
            elif t.startswith('report_timing '):reports.append(t)
            else:ordinary.append(t)
        return ordinary,minimum,reports
    a,ma,ra=split(before);b,mb,rb=split(after)
    assert a==b,'Clock, exception, group or other timing command changed'
    assert all(target in mb and mb[target]>=v for target,v in ma.items()),'A previous minimum-delay requirement was removed or relaxed'
    assert mb!=ma or rb!=ra,'No stricter minimum or report change'
    return dict(previous_minimums=ma,new_minimums=mb,report_commands=rb,
                scope='Same clocks/groups/exceptions; only equal-or-higher existing minimums, added positive minimums and report commands allowed.')
