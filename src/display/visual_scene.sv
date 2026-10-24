`default_nettype none
// Native scene composition over sharp and genuinely prefiltered scenery ROMs.
module visual_scene #(parameter MATERIAL_SAMPLE=0,parameter BACKGROUND_LATENCY=0)(input wire [11:0] x,y,input wire status_live,input wire [511:0] status_data,output wire [23:0] rgb,
 input wire signed [9:0] drift_x,drift_y,input wire [95:0] key_trails,
 input wire [23:0] sharp_rgb,frost_rgb,input wire clk) /* synthesis syn_srlstyle="distributed_ram" */;

 function automatic signed [13:0] ab(input signed [13:0] v);begin ab=v<0?-v:v;end endfunction
 function automatic integer clamp(input integer v,lo,hi);begin clamp=v<lo?lo:v>hi?hi:v;end endfunction
 function automatic [6:0] circle_limit(input [5:0] radius,dx);
  begin case({radius,dx})
   12'd0:circle_limit=7'd64;
   12'd64:circle_limit=7'd65;
   12'd65:circle_limit=7'd64;
   12'd128:circle_limit=7'd66;
   12'd129:circle_limit=7'd65;
   12'd130:circle_limit=7'd64;
   12'd192:circle_limit=7'd67;
   12'd193:circle_limit=7'd66;
   12'd194:circle_limit=7'd66;
   12'd195:circle_limit=7'd64;
   12'd256:circle_limit=7'd68;
   12'd257:circle_limit=7'd67;
   12'd258:circle_limit=7'd67;
   12'd259:circle_limit=7'd66;
   12'd260:circle_limit=7'd64;
   12'd320:circle_limit=7'd69;
   12'd321:circle_limit=7'd68;
   12'd322:circle_limit=7'd68;
   12'd323:circle_limit=7'd68;
   12'd324:circle_limit=7'd67;
   12'd325:circle_limit=7'd64;
   12'd384:circle_limit=7'd70;
   12'd385:circle_limit=7'd69;
   12'd386:circle_limit=7'd69;
   12'd387:circle_limit=7'd69;
   12'd388:circle_limit=7'd68;
   12'd389:circle_limit=7'd67;
   12'd390:circle_limit=7'd64;
   12'd448:circle_limit=7'd71;
   12'd449:circle_limit=7'd70;
   12'd450:circle_limit=7'd70;
   12'd451:circle_limit=7'd70;
   12'd452:circle_limit=7'd69;
   12'd453:circle_limit=7'd68;
   12'd454:circle_limit=7'd67;
   12'd455:circle_limit=7'd64;
   12'd512:circle_limit=7'd72;
   12'd513:circle_limit=7'd71;
   12'd514:circle_limit=7'd71;
   12'd515:circle_limit=7'd71;
   12'd516:circle_limit=7'd70;
   12'd517:circle_limit=7'd70;
   12'd518:circle_limit=7'd69;
   12'd519:circle_limit=7'd67;
   12'd520:circle_limit=7'd64;
   12'd576:circle_limit=7'd73;
   12'd577:circle_limit=7'd72;
   12'd578:circle_limit=7'd72;
   12'd579:circle_limit=7'd72;
   12'd580:circle_limit=7'd72;
   12'd581:circle_limit=7'd71;
   12'd582:circle_limit=7'd70;
   12'd583:circle_limit=7'd69;
   12'd584:circle_limit=7'd68;
   12'd585:circle_limit=7'd64;
   12'd640:circle_limit=7'd74;
   12'd641:circle_limit=7'd73;
   12'd642:circle_limit=7'd73;
   12'd643:circle_limit=7'd73;
   12'd644:circle_limit=7'd73;
   12'd645:circle_limit=7'd72;
   12'd646:circle_limit=7'd72;
   12'd647:circle_limit=7'd71;
   12'd648:circle_limit=7'd70;
   12'd649:circle_limit=7'd68;
   12'd650:circle_limit=7'd64;
   12'd704:circle_limit=7'd75;
   12'd705:circle_limit=7'd74;
   12'd706:circle_limit=7'd74;
   12'd707:circle_limit=7'd74;
   12'd708:circle_limit=7'd74;
   12'd709:circle_limit=7'd73;
   12'd710:circle_limit=7'd73;
   12'd711:circle_limit=7'd72;
   12'd712:circle_limit=7'd71;
   12'd713:circle_limit=7'd70;
   12'd714:circle_limit=7'd68;
   12'd715:circle_limit=7'd64;
   12'd768:circle_limit=7'd76;
   12'd769:circle_limit=7'd75;
   12'd770:circle_limit=7'd75;
   12'd771:circle_limit=7'd75;
   12'd772:circle_limit=7'd75;
   12'd773:circle_limit=7'd74;
   12'd774:circle_limit=7'd74;
   12'd775:circle_limit=7'd73;
   12'd776:circle_limit=7'd72;
   12'd777:circle_limit=7'd71;
   12'd778:circle_limit=7'd70;
   12'd779:circle_limit=7'd68;
   12'd780:circle_limit=7'd64;
   12'd832:circle_limit=7'd77;
   12'd833:circle_limit=7'd76;
   12'd834:circle_limit=7'd76;
   12'd835:circle_limit=7'd76;
   12'd836:circle_limit=7'd76;
   12'd837:circle_limit=7'd76;
   12'd838:circle_limit=7'd75;
   12'd839:circle_limit=7'd74;
   12'd840:circle_limit=7'd74;
   12'd841:circle_limit=7'd73;
   12'd842:circle_limit=7'd72;
   12'd843:circle_limit=7'd70;
   12'd844:circle_limit=7'd69;
   12'd845:circle_limit=7'd64;
   12'd896:circle_limit=7'd78;
   12'd897:circle_limit=7'd77;
   12'd898:circle_limit=7'd77;
   12'd899:circle_limit=7'd77;
   12'd900:circle_limit=7'd77;
   12'd901:circle_limit=7'd77;
   12'd902:circle_limit=7'd76;
   12'd903:circle_limit=7'd76;
   12'd904:circle_limit=7'd75;
   12'd905:circle_limit=7'd74;
   12'd906:circle_limit=7'd73;
   12'd907:circle_limit=7'd72;
   12'd908:circle_limit=7'd71;
   12'd909:circle_limit=7'd69;
   12'd910:circle_limit=7'd64;
   12'd960:circle_limit=7'd79;
   12'd961:circle_limit=7'd78;
   12'd962:circle_limit=7'd78;
   12'd963:circle_limit=7'd78;
   12'd964:circle_limit=7'd78;
   12'd965:circle_limit=7'd78;
   12'd966:circle_limit=7'd77;
   12'd967:circle_limit=7'd77;
   12'd968:circle_limit=7'd76;
   12'd969:circle_limit=7'd76;
   12'd970:circle_limit=7'd75;
   12'd971:circle_limit=7'd74;
   12'd972:circle_limit=7'd73;
   12'd973:circle_limit=7'd71;
   12'd974:circle_limit=7'd69;
   12'd975:circle_limit=7'd64;
   12'd1024:circle_limit=7'd80;
   12'd1025:circle_limit=7'd79;
   12'd1026:circle_limit=7'd79;
   12'd1027:circle_limit=7'd79;
   12'd1028:circle_limit=7'd79;
   12'd1029:circle_limit=7'd79;
   12'd1030:circle_limit=7'd78;
   12'd1031:circle_limit=7'd78;
   12'd1032:circle_limit=7'd77;
   12'd1033:circle_limit=7'd77;
   12'd1034:circle_limit=7'd76;
   12'd1035:circle_limit=7'd75;
   12'd1036:circle_limit=7'd74;
   12'd1037:circle_limit=7'd73;
   12'd1038:circle_limit=7'd71;
   12'd1039:circle_limit=7'd69;
   12'd1040:circle_limit=7'd64;
   12'd1088:circle_limit=7'd81;
   12'd1089:circle_limit=7'd80;
   12'd1090:circle_limit=7'd80;
   12'd1091:circle_limit=7'd80;
   12'd1092:circle_limit=7'd80;
   12'd1093:circle_limit=7'd80;
   12'd1094:circle_limit=7'd79;
   12'd1095:circle_limit=7'd79;
   12'd1096:circle_limit=7'd79;
   12'd1097:circle_limit=7'd78;
   12'd1098:circle_limit=7'd77;
   12'd1099:circle_limit=7'd76;
   12'd1100:circle_limit=7'd76;
   12'd1101:circle_limit=7'd74;
   12'd1102:circle_limit=7'd73;
   12'd1103:circle_limit=7'd72;
   12'd1104:circle_limit=7'd69;
   12'd1105:circle_limit=7'd64;
   12'd1152:circle_limit=7'd82;
   12'd1153:circle_limit=7'd81;
   12'd1154:circle_limit=7'd81;
   12'd1155:circle_limit=7'd81;
   12'd1156:circle_limit=7'd81;
   12'd1157:circle_limit=7'd81;
   12'd1158:circle_limit=7'd80;
   12'd1159:circle_limit=7'd80;
   12'd1160:circle_limit=7'd80;
   12'd1161:circle_limit=7'd79;
   12'd1162:circle_limit=7'd78;
   12'd1163:circle_limit=7'd78;
   12'd1164:circle_limit=7'd77;
   12'd1165:circle_limit=7'd76;
   12'd1166:circle_limit=7'd75;
   12'd1167:circle_limit=7'd73;
   12'd1168:circle_limit=7'd72;
   12'd1169:circle_limit=7'd69;
   12'd1170:circle_limit=7'd64;
   12'd1216:circle_limit=7'd83;
   12'd1217:circle_limit=7'd82;
   12'd1218:circle_limit=7'd82;
   12'd1219:circle_limit=7'd82;
   12'd1220:circle_limit=7'd82;
   12'd1221:circle_limit=7'd82;
   12'd1222:circle_limit=7'd82;
   12'd1223:circle_limit=7'd81;
   12'd1224:circle_limit=7'd81;
   12'd1225:circle_limit=7'd80;
   12'd1226:circle_limit=7'd80;
   12'd1227:circle_limit=7'd79;
   12'd1228:circle_limit=7'd78;
   12'd1229:circle_limit=7'd77;
   12'd1230:circle_limit=7'd76;
   12'd1231:circle_limit=7'd75;
   12'd1232:circle_limit=7'd74;
   12'd1233:circle_limit=7'd72;
   12'd1234:circle_limit=7'd70;
   12'd1235:circle_limit=7'd64;
   12'd1280:circle_limit=7'd84;
   12'd1281:circle_limit=7'd83;
   12'd1282:circle_limit=7'd83;
   12'd1283:circle_limit=7'd83;
   12'd1284:circle_limit=7'd83;
   12'd1285:circle_limit=7'd83;
   12'd1286:circle_limit=7'd83;
   12'd1287:circle_limit=7'd82;
   12'd1288:circle_limit=7'd82;
   12'd1289:circle_limit=7'd81;
   12'd1290:circle_limit=7'd81;
   12'd1291:circle_limit=7'd80;
   12'd1292:circle_limit=7'd80;
   12'd1293:circle_limit=7'd79;
   12'd1294:circle_limit=7'd78;
   12'd1295:circle_limit=7'd77;
   12'd1296:circle_limit=7'd76;
   12'd1297:circle_limit=7'd74;
   12'd1298:circle_limit=7'd72;
   12'd1299:circle_limit=7'd70;
   12'd1300:circle_limit=7'd64;
   12'd1344:circle_limit=7'd85;
   12'd1345:circle_limit=7'd84;
   12'd1346:circle_limit=7'd84;
   12'd1347:circle_limit=7'd84;
   12'd1348:circle_limit=7'd84;
   12'd1349:circle_limit=7'd84;
   12'd1350:circle_limit=7'd84;
   12'd1351:circle_limit=7'd83;
   12'd1352:circle_limit=7'd83;
   12'd1353:circle_limit=7'd82;
   12'd1354:circle_limit=7'd82;
   12'd1355:circle_limit=7'd81;
   12'd1356:circle_limit=7'd81;
   12'd1357:circle_limit=7'd80;
   12'd1358:circle_limit=7'd79;
   12'd1359:circle_limit=7'd78;
   12'd1360:circle_limit=7'd77;
   12'd1361:circle_limit=7'd76;
   12'd1362:circle_limit=7'd74;
   12'd1363:circle_limit=7'd72;
   12'd1364:circle_limit=7'd70;
   12'd1365:circle_limit=7'd64;
   12'd1408:circle_limit=7'd86;
   12'd1409:circle_limit=7'd85;
   12'd1410:circle_limit=7'd85;
   12'd1411:circle_limit=7'd85;
   12'd1412:circle_limit=7'd85;
   12'd1413:circle_limit=7'd85;
   12'd1414:circle_limit=7'd85;
   12'd1415:circle_limit=7'd84;
   12'd1416:circle_limit=7'd84;
   12'd1417:circle_limit=7'd84;
   12'd1418:circle_limit=7'd83;
   12'd1419:circle_limit=7'd83;
   12'd1420:circle_limit=7'd82;
   12'd1421:circle_limit=7'd81;
   12'd1422:circle_limit=7'd80;
   12'd1423:circle_limit=7'd80;
   12'd1424:circle_limit=7'd79;
   12'd1425:circle_limit=7'd77;
   12'd1426:circle_limit=7'd76;
   12'd1427:circle_limit=7'd75;
   12'd1428:circle_limit=7'd73;
   12'd1429:circle_limit=7'd70;
   12'd1430:circle_limit=7'd64;
   12'd1472:circle_limit=7'd87;
   12'd1473:circle_limit=7'd86;
   12'd1474:circle_limit=7'd86;
   12'd1475:circle_limit=7'd86;
   12'd1476:circle_limit=7'd86;
   12'd1477:circle_limit=7'd86;
   12'd1478:circle_limit=7'd86;
   12'd1479:circle_limit=7'd85;
   12'd1480:circle_limit=7'd85;
   12'd1481:circle_limit=7'd85;
   12'd1482:circle_limit=7'd84;
   12'd1483:circle_limit=7'd84;
   12'd1484:circle_limit=7'd83;
   12'd1485:circle_limit=7'd82;
   12'd1486:circle_limit=7'd82;
   12'd1487:circle_limit=7'd81;
   12'd1488:circle_limit=7'd80;
   12'd1489:circle_limit=7'd79;
   12'd1490:circle_limit=7'd78;
   12'd1491:circle_limit=7'd76;
   12'd1492:circle_limit=7'd75;
   12'd1493:circle_limit=7'd73;
   12'd1494:circle_limit=7'd70;
   12'd1495:circle_limit=7'd64;
   12'd1536:circle_limit=7'd88;
   12'd1537:circle_limit=7'd87;
   12'd1538:circle_limit=7'd87;
   12'd1539:circle_limit=7'd87;
   12'd1540:circle_limit=7'd87;
   12'd1541:circle_limit=7'd87;
   12'd1542:circle_limit=7'd87;
   12'd1543:circle_limit=7'd86;
   12'd1544:circle_limit=7'd86;
   12'd1545:circle_limit=7'd86;
   12'd1546:circle_limit=7'd85;
   12'd1547:circle_limit=7'd85;
   12'd1548:circle_limit=7'd84;
   12'd1549:circle_limit=7'd84;
   12'd1550:circle_limit=7'd83;
   12'd1551:circle_limit=7'd82;
   12'd1552:circle_limit=7'd81;
   12'd1553:circle_limit=7'd80;
   12'd1554:circle_limit=7'd79;
   12'd1555:circle_limit=7'd78;
   12'd1556:circle_limit=7'd77;
   12'd1557:circle_limit=7'd75;
   12'd1558:circle_limit=7'd73;
   12'd1559:circle_limit=7'd70;
   12'd1560:circle_limit=7'd64;
   12'd1600:circle_limit=7'd89;
   12'd1601:circle_limit=7'd88;
   12'd1602:circle_limit=7'd88;
   12'd1603:circle_limit=7'd88;
   12'd1604:circle_limit=7'd88;
   12'd1605:circle_limit=7'd88;
   12'd1606:circle_limit=7'd88;
   12'd1607:circle_limit=7'd88;
   12'd1608:circle_limit=7'd87;
   12'd1609:circle_limit=7'd87;
   12'd1610:circle_limit=7'd86;
   12'd1611:circle_limit=7'd86;
   12'd1612:circle_limit=7'd85;
   12'd1613:circle_limit=7'd85;
   12'd1614:circle_limit=7'd84;
   12'd1615:circle_limit=7'd84;
   12'd1616:circle_limit=7'd83;
   12'd1617:circle_limit=7'd82;
   12'd1618:circle_limit=7'd81;
   12'd1619:circle_limit=7'd80;
   12'd1620:circle_limit=7'd79;
   12'd1621:circle_limit=7'd77;
   12'd1622:circle_limit=7'd75;
   12'd1623:circle_limit=7'd73;
   12'd1624:circle_limit=7'd71;
   12'd1625:circle_limit=7'd64;
   12'd1664:circle_limit=7'd90;
   12'd1665:circle_limit=7'd89;
   12'd1666:circle_limit=7'd89;
   12'd1667:circle_limit=7'd89;
   12'd1668:circle_limit=7'd89;
   12'd1669:circle_limit=7'd89;
   12'd1670:circle_limit=7'd89;
   12'd1671:circle_limit=7'd89;
   12'd1672:circle_limit=7'd88;
   12'd1673:circle_limit=7'd88;
   12'd1674:circle_limit=7'd88;
   12'd1675:circle_limit=7'd87;
   12'd1676:circle_limit=7'd87;
   12'd1677:circle_limit=7'd86;
   12'd1678:circle_limit=7'd85;
   12'd1679:circle_limit=7'd85;
   12'd1680:circle_limit=7'd84;
   12'd1681:circle_limit=7'd83;
   12'd1682:circle_limit=7'd82;
   12'd1683:circle_limit=7'd81;
   12'd1684:circle_limit=7'd80;
   12'd1685:circle_limit=7'd79;
   12'd1686:circle_limit=7'd77;
   12'd1687:circle_limit=7'd76;
   12'd1688:circle_limit=7'd74;
   12'd1689:circle_limit=7'd71;
   12'd1690:circle_limit=7'd64;
   12'd1728:circle_limit=7'd91;
   12'd1729:circle_limit=7'd90;
   12'd1730:circle_limit=7'd90;
   12'd1731:circle_limit=7'd90;
   12'd1732:circle_limit=7'd90;
   12'd1733:circle_limit=7'd90;
   12'd1734:circle_limit=7'd90;
   12'd1735:circle_limit=7'd90;
   12'd1736:circle_limit=7'd89;
   12'd1737:circle_limit=7'd89;
   12'd1738:circle_limit=7'd89;
   12'd1739:circle_limit=7'd88;
   12'd1740:circle_limit=7'd88;
   12'd1741:circle_limit=7'd87;
   12'd1742:circle_limit=7'd87;
   12'd1743:circle_limit=7'd86;
   12'd1744:circle_limit=7'd85;
   12'd1745:circle_limit=7'd84;
   12'd1746:circle_limit=7'd84;
   12'd1747:circle_limit=7'd83;
   12'd1748:circle_limit=7'd82;
   12'd1749:circle_limit=7'd80;
   12'd1750:circle_limit=7'd79;
   12'd1751:circle_limit=7'd78;
   12'd1752:circle_limit=7'd76;
   12'd1753:circle_limit=7'd74;
   12'd1754:circle_limit=7'd71;
   12'd1755:circle_limit=7'd64;
   12'd1792:circle_limit=7'd92;
   12'd1793:circle_limit=7'd91;
   12'd1794:circle_limit=7'd91;
   12'd1795:circle_limit=7'd91;
   12'd1796:circle_limit=7'd91;
   12'd1797:circle_limit=7'd91;
   12'd1798:circle_limit=7'd91;
   12'd1799:circle_limit=7'd91;
   12'd1800:circle_limit=7'd90;
   12'd1801:circle_limit=7'd90;
   12'd1802:circle_limit=7'd90;
   12'd1803:circle_limit=7'd89;
   12'd1804:circle_limit=7'd89;
   12'd1805:circle_limit=7'd88;
   12'd1806:circle_limit=7'd88;
   12'd1807:circle_limit=7'd87;
   12'd1808:circle_limit=7'd86;
   12'd1809:circle_limit=7'd86;
   12'd1810:circle_limit=7'd85;
   12'd1811:circle_limit=7'd84;
   12'd1812:circle_limit=7'd83;
   12'd1813:circle_limit=7'd82;
   12'd1814:circle_limit=7'd81;
   12'd1815:circle_limit=7'd79;
   12'd1816:circle_limit=7'd78;
   12'd1817:circle_limit=7'd76;
   12'd1818:circle_limit=7'd74;
   12'd1819:circle_limit=7'd71;
   12'd1820:circle_limit=7'd64;
   12'd1856:circle_limit=7'd93;
   12'd1857:circle_limit=7'd92;
   12'd1858:circle_limit=7'd92;
   12'd1859:circle_limit=7'd92;
   12'd1860:circle_limit=7'd92;
   12'd1861:circle_limit=7'd92;
   12'd1862:circle_limit=7'd92;
   12'd1863:circle_limit=7'd92;
   12'd1864:circle_limit=7'd91;
   12'd1865:circle_limit=7'd91;
   12'd1866:circle_limit=7'd91;
   12'd1867:circle_limit=7'd90;
   12'd1868:circle_limit=7'd90;
   12'd1869:circle_limit=7'd89;
   12'd1870:circle_limit=7'd89;
   12'd1871:circle_limit=7'd88;
   12'd1872:circle_limit=7'd88;
   12'd1873:circle_limit=7'd87;
   12'd1874:circle_limit=7'd86;
   12'd1875:circle_limit=7'd85;
   12'd1876:circle_limit=7'd85;
   12'd1877:circle_limit=7'd84;
   12'd1878:circle_limit=7'd82;
   12'd1879:circle_limit=7'd81;
   12'd1880:circle_limit=7'd80;
   12'd1881:circle_limit=7'd78;
   12'd1882:circle_limit=7'd76;
   12'd1883:circle_limit=7'd74;
   12'd1884:circle_limit=7'd71;
   12'd1885:circle_limit=7'd64;
   12'd1920:circle_limit=7'd94;
   12'd1921:circle_limit=7'd93;
   12'd1922:circle_limit=7'd93;
   12'd1923:circle_limit=7'd93;
   12'd1924:circle_limit=7'd93;
   12'd1925:circle_limit=7'd93;
   12'd1926:circle_limit=7'd93;
   12'd1927:circle_limit=7'd93;
   12'd1928:circle_limit=7'd92;
   12'd1929:circle_limit=7'd92;
   12'd1930:circle_limit=7'd92;
   12'd1931:circle_limit=7'd91;
   12'd1932:circle_limit=7'd91;
   12'd1933:circle_limit=7'd91;
   12'd1934:circle_limit=7'd90;
   12'd1935:circle_limit=7'd89;
   12'd1936:circle_limit=7'd89;
   12'd1937:circle_limit=7'd88;
   12'd1938:circle_limit=7'd88;
   12'd1939:circle_limit=7'd87;
   12'd1940:circle_limit=7'd86;
   12'd1941:circle_limit=7'd85;
   12'd1942:circle_limit=7'd84;
   12'd1943:circle_limit=7'd83;
   12'd1944:circle_limit=7'd82;
   12'd1945:circle_limit=7'd80;
   12'd1946:circle_limit=7'd78;
   12'd1947:circle_limit=7'd77;
   12'd1948:circle_limit=7'd74;
   12'd1949:circle_limit=7'd71;
   12'd1950:circle_limit=7'd64;
   12'd1984:circle_limit=7'd95;
   12'd1985:circle_limit=7'd94;
   12'd1986:circle_limit=7'd94;
   12'd1987:circle_limit=7'd94;
   12'd1988:circle_limit=7'd94;
   12'd1989:circle_limit=7'd94;
   12'd1990:circle_limit=7'd94;
   12'd1991:circle_limit=7'd94;
   12'd1992:circle_limit=7'd93;
   12'd1993:circle_limit=7'd93;
   12'd1994:circle_limit=7'd93;
   12'd1995:circle_limit=7'd92;
   12'd1996:circle_limit=7'd92;
   12'd1997:circle_limit=7'd92;
   12'd1998:circle_limit=7'd91;
   12'd1999:circle_limit=7'd91;
   12'd2000:circle_limit=7'd90;
   12'd2001:circle_limit=7'd89;
   12'd2002:circle_limit=7'd89;
   12'd2003:circle_limit=7'd88;
   12'd2004:circle_limit=7'd87;
   12'd2005:circle_limit=7'd86;
   12'd2006:circle_limit=7'd85;
   12'd2007:circle_limit=7'd84;
   12'd2008:circle_limit=7'd83;
   12'd2009:circle_limit=7'd82;
   12'd2010:circle_limit=7'd80;
   12'd2011:circle_limit=7'd79;
   12'd2012:circle_limit=7'd77;
   12'd2013:circle_limit=7'd74;
   12'd2014:circle_limit=7'd71;
   12'd2015:circle_limit=7'd64;
   12'd2048:circle_limit=7'd96;
   12'd2049:circle_limit=7'd95;
   12'd2050:circle_limit=7'd95;
   12'd2051:circle_limit=7'd95;
   12'd2052:circle_limit=7'd95;
   12'd2053:circle_limit=7'd95;
   12'd2054:circle_limit=7'd95;
   12'd2055:circle_limit=7'd95;
   12'd2056:circle_limit=7'd94;
   12'd2057:circle_limit=7'd94;
   12'd2058:circle_limit=7'd94;
   12'd2059:circle_limit=7'd94;
   12'd2060:circle_limit=7'd93;
   12'd2061:circle_limit=7'd93;
   12'd2062:circle_limit=7'd92;
   12'd2063:circle_limit=7'd92;
   12'd2064:circle_limit=7'd91;
   12'd2065:circle_limit=7'd91;
   12'd2066:circle_limit=7'd90;
   12'd2067:circle_limit=7'd89;
   12'd2068:circle_limit=7'd88;
   12'd2069:circle_limit=7'd88;
   12'd2070:circle_limit=7'd87;
   12'd2071:circle_limit=7'd86;
   12'd2072:circle_limit=7'd85;
   12'd2073:circle_limit=7'd83;
   12'd2074:circle_limit=7'd82;
   12'd2075:circle_limit=7'd81;
   12'd2076:circle_limit=7'd79;
   12'd2077:circle_limit=7'd77;
   12'd2078:circle_limit=7'd75;
   12'd2079:circle_limit=7'd71;
   12'd2080:circle_limit=7'd64;
   12'd2112:circle_limit=7'd97;
   12'd2113:circle_limit=7'd96;
   12'd2114:circle_limit=7'd96;
   12'd2115:circle_limit=7'd96;
   12'd2116:circle_limit=7'd96;
   12'd2117:circle_limit=7'd96;
   12'd2118:circle_limit=7'd96;
   12'd2119:circle_limit=7'd96;
   12'd2120:circle_limit=7'd96;
   12'd2121:circle_limit=7'd95;
   12'd2122:circle_limit=7'd95;
   12'd2123:circle_limit=7'd95;
   12'd2124:circle_limit=7'd94;
   12'd2125:circle_limit=7'd94;
   12'd2126:circle_limit=7'd93;
   12'd2127:circle_limit=7'd93;
   12'd2128:circle_limit=7'd92;
   12'd2129:circle_limit=7'd92;
   12'd2130:circle_limit=7'd91;
   12'd2131:circle_limit=7'd90;
   12'd2132:circle_limit=7'd90;
   12'd2133:circle_limit=7'd89;
   12'd2134:circle_limit=7'd88;
   12'd2135:circle_limit=7'd87;
   12'd2136:circle_limit=7'd86;
   12'd2137:circle_limit=7'd85;
   12'd2138:circle_limit=7'd84;
   12'd2139:circle_limit=7'd82;
   12'd2140:circle_limit=7'd81;
   12'd2141:circle_limit=7'd79;
   12'd2142:circle_limit=7'd77;
   12'd2143:circle_limit=7'd75;
   12'd2144:circle_limit=7'd72;
   12'd2145:circle_limit=7'd64;
   12'd2176:circle_limit=7'd98;
   12'd2177:circle_limit=7'd97;
   12'd2178:circle_limit=7'd97;
   12'd2179:circle_limit=7'd97;
   12'd2180:circle_limit=7'd97;
   12'd2181:circle_limit=7'd97;
   12'd2182:circle_limit=7'd97;
   12'd2183:circle_limit=7'd97;
   12'd2184:circle_limit=7'd97;
   12'd2185:circle_limit=7'd96;
   12'd2186:circle_limit=7'd96;
   12'd2187:circle_limit=7'd96;
   12'd2188:circle_limit=7'd95;
   12'd2189:circle_limit=7'd95;
   12'd2190:circle_limit=7'd94;
   12'd2191:circle_limit=7'd94;
   12'd2192:circle_limit=7'd94;
   12'd2193:circle_limit=7'd93;
   12'd2194:circle_limit=7'd92;
   12'd2195:circle_limit=7'd92;
   12'd2196:circle_limit=7'd91;
   12'd2197:circle_limit=7'd90;
   12'd2198:circle_limit=7'd89;
   12'd2199:circle_limit=7'd89;
   12'd2200:circle_limit=7'd88;
   12'd2201:circle_limit=7'd87;
   12'd2202:circle_limit=7'd85;
   12'd2203:circle_limit=7'd84;
   12'd2204:circle_limit=7'd83;
   12'd2205:circle_limit=7'd81;
   12'd2206:circle_limit=7'd80;
   12'd2207:circle_limit=7'd77;
   12'd2208:circle_limit=7'd75;
   12'd2209:circle_limit=7'd72;
   12'd2210:circle_limit=7'd64;
   12'd2240:circle_limit=7'd99;
   12'd2241:circle_limit=7'd98;
   12'd2242:circle_limit=7'd98;
   12'd2243:circle_limit=7'd98;
   12'd2244:circle_limit=7'd98;
   12'd2245:circle_limit=7'd98;
   12'd2246:circle_limit=7'd98;
   12'd2247:circle_limit=7'd98;
   12'd2248:circle_limit=7'd98;
   12'd2249:circle_limit=7'd97;
   12'd2250:circle_limit=7'd97;
   12'd2251:circle_limit=7'd97;
   12'd2252:circle_limit=7'd96;
   12'd2253:circle_limit=7'd96;
   12'd2254:circle_limit=7'd96;
   12'd2255:circle_limit=7'd95;
   12'd2256:circle_limit=7'd95;
   12'd2257:circle_limit=7'd94;
   12'd2258:circle_limit=7'd94;
   12'd2259:circle_limit=7'd93;
   12'd2260:circle_limit=7'd92;
   12'd2261:circle_limit=7'd92;
   12'd2262:circle_limit=7'd91;
   12'd2263:circle_limit=7'd90;
   12'd2264:circle_limit=7'd89;
   12'd2265:circle_limit=7'd88;
   12'd2266:circle_limit=7'd87;
   12'd2267:circle_limit=7'd86;
   12'd2268:circle_limit=7'd85;
   12'd2269:circle_limit=7'd83;
   12'd2270:circle_limit=7'd82;
   12'd2271:circle_limit=7'd80;
   12'd2272:circle_limit=7'd78;
   12'd2273:circle_limit=7'd75;
   12'd2274:circle_limit=7'd72;
   12'd2275:circle_limit=7'd64;
   12'd2304:circle_limit=7'd100;
   12'd2305:circle_limit=7'd99;
   12'd2306:circle_limit=7'd99;
   12'd2307:circle_limit=7'd99;
   12'd2308:circle_limit=7'd99;
   12'd2309:circle_limit=7'd99;
   12'd2310:circle_limit=7'd99;
   12'd2311:circle_limit=7'd99;
   12'd2312:circle_limit=7'd99;
   12'd2313:circle_limit=7'd98;
   12'd2314:circle_limit=7'd98;
   12'd2315:circle_limit=7'd98;
   12'd2316:circle_limit=7'd97;
   12'd2317:circle_limit=7'd97;
   12'd2318:circle_limit=7'd97;
   12'd2319:circle_limit=7'd96;
   12'd2320:circle_limit=7'd96;
   12'd2321:circle_limit=7'd95;
   12'd2322:circle_limit=7'd95;
   12'd2323:circle_limit=7'd94;
   12'd2324:circle_limit=7'd93;
   12'd2325:circle_limit=7'd93;
   12'd2326:circle_limit=7'd92;
   12'd2327:circle_limit=7'd91;
   12'd2328:circle_limit=7'd90;
   12'd2329:circle_limit=7'd89;
   12'd2330:circle_limit=7'd88;
   12'd2331:circle_limit=7'd87;
   12'd2332:circle_limit=7'd86;
   12'd2333:circle_limit=7'd85;
   12'd2334:circle_limit=7'd83;
   12'd2335:circle_limit=7'd82;
   12'd2336:circle_limit=7'd80;
   12'd2337:circle_limit=7'd78;
   12'd2338:circle_limit=7'd75;
   12'd2339:circle_limit=7'd72;
   12'd2340:circle_limit=7'd64;
   12'd2368:circle_limit=7'd101;
   12'd2369:circle_limit=7'd100;
   12'd2370:circle_limit=7'd100;
   12'd2371:circle_limit=7'd100;
   12'd2372:circle_limit=7'd100;
   12'd2373:circle_limit=7'd100;
   12'd2374:circle_limit=7'd100;
   12'd2375:circle_limit=7'd100;
   12'd2376:circle_limit=7'd100;
   12'd2377:circle_limit=7'd99;
   12'd2378:circle_limit=7'd99;
   12'd2379:circle_limit=7'd99;
   12'd2380:circle_limit=7'd99;
   12'd2381:circle_limit=7'd98;
   12'd2382:circle_limit=7'd98;
   12'd2383:circle_limit=7'd97;
   12'd2384:circle_limit=7'd97;
   12'd2385:circle_limit=7'd96;
   12'd2386:circle_limit=7'd96;
   12'd2387:circle_limit=7'd95;
   12'd2388:circle_limit=7'd95;
   12'd2389:circle_limit=7'd94;
   12'd2390:circle_limit=7'd93;
   12'd2391:circle_limit=7'd92;
   12'd2392:circle_limit=7'd92;
   12'd2393:circle_limit=7'd91;
   12'd2394:circle_limit=7'd90;
   12'd2395:circle_limit=7'd89;
   12'd2396:circle_limit=7'd88;
   12'd2397:circle_limit=7'd86;
   12'd2398:circle_limit=7'd85;
   12'd2399:circle_limit=7'd84;
   12'd2400:circle_limit=7'd82;
   12'd2401:circle_limit=7'd80;
   12'd2402:circle_limit=7'd78;
   12'd2403:circle_limit=7'd76;
   12'd2404:circle_limit=7'd72;
   12'd2405:circle_limit=7'd64;
   12'd2432:circle_limit=7'd102;
   12'd2433:circle_limit=7'd101;
   12'd2434:circle_limit=7'd101;
   12'd2435:circle_limit=7'd101;
   12'd2436:circle_limit=7'd101;
   12'd2437:circle_limit=7'd101;
   12'd2438:circle_limit=7'd101;
   12'd2439:circle_limit=7'd101;
   12'd2440:circle_limit=7'd101;
   12'd2441:circle_limit=7'd100;
   12'd2442:circle_limit=7'd100;
   12'd2443:circle_limit=7'd100;
   12'd2444:circle_limit=7'd100;
   12'd2445:circle_limit=7'd99;
   12'd2446:circle_limit=7'd99;
   12'd2447:circle_limit=7'd98;
   12'd2448:circle_limit=7'd98;
   12'd2449:circle_limit=7'd97;
   12'd2450:circle_limit=7'd97;
   12'd2451:circle_limit=7'd96;
   12'd2452:circle_limit=7'd96;
   12'd2453:circle_limit=7'd95;
   12'd2454:circle_limit=7'd94;
   12'd2455:circle_limit=7'd94;
   12'd2456:circle_limit=7'd93;
   12'd2457:circle_limit=7'd92;
   12'd2458:circle_limit=7'd91;
   12'd2459:circle_limit=7'd90;
   12'd2460:circle_limit=7'd89;
   12'd2461:circle_limit=7'd88;
   12'd2462:circle_limit=7'd87;
   12'd2463:circle_limit=7'd85;
   12'd2464:circle_limit=7'd84;
   12'd2465:circle_limit=7'd82;
   12'd2466:circle_limit=7'd80;
   12'd2467:circle_limit=7'd78;
   12'd2468:circle_limit=7'd76;
   12'd2469:circle_limit=7'd72;
   12'd2470:circle_limit=7'd64;
   12'd2496:circle_limit=7'd103;
   12'd2497:circle_limit=7'd102;
   12'd2498:circle_limit=7'd102;
   12'd2499:circle_limit=7'd102;
   12'd2500:circle_limit=7'd102;
   12'd2501:circle_limit=7'd102;
   12'd2502:circle_limit=7'd102;
   12'd2503:circle_limit=7'd102;
   12'd2504:circle_limit=7'd102;
   12'd2505:circle_limit=7'd101;
   12'd2506:circle_limit=7'd101;
   12'd2507:circle_limit=7'd101;
   12'd2508:circle_limit=7'd101;
   12'd2509:circle_limit=7'd100;
   12'd2510:circle_limit=7'd100;
   12'd2511:circle_limit=7'd100;
   12'd2512:circle_limit=7'd99;
   12'd2513:circle_limit=7'd99;
   12'd2514:circle_limit=7'd98;
   12'd2515:circle_limit=7'd98;
   12'd2516:circle_limit=7'd97;
   12'd2517:circle_limit=7'd96;
   12'd2518:circle_limit=7'd96;
   12'd2519:circle_limit=7'd95;
   12'd2520:circle_limit=7'd94;
   12'd2521:circle_limit=7'd93;
   12'd2522:circle_limit=7'd93;
   12'd2523:circle_limit=7'd92;
   12'd2524:circle_limit=7'd91;
   12'd2525:circle_limit=7'd90;
   12'd2526:circle_limit=7'd88;
   12'd2527:circle_limit=7'd87;
   12'd2528:circle_limit=7'd86;
   12'd2529:circle_limit=7'd84;
   12'd2530:circle_limit=7'd83;
   12'd2531:circle_limit=7'd81;
   12'd2532:circle_limit=7'd79;
   12'd2533:circle_limit=7'd76;
   12'd2534:circle_limit=7'd72;
   12'd2535:circle_limit=7'd64;
   12'd2560:circle_limit=7'd104;
   12'd2561:circle_limit=7'd103;
   12'd2562:circle_limit=7'd103;
   12'd2563:circle_limit=7'd103;
   12'd2564:circle_limit=7'd103;
   12'd2565:circle_limit=7'd103;
   12'd2566:circle_limit=7'd103;
   12'd2567:circle_limit=7'd103;
   12'd2568:circle_limit=7'd103;
   12'd2569:circle_limit=7'd102;
   12'd2570:circle_limit=7'd102;
   12'd2571:circle_limit=7'd102;
   12'd2572:circle_limit=7'd102;
   12'd2573:circle_limit=7'd101;
   12'd2574:circle_limit=7'd101;
   12'd2575:circle_limit=7'd101;
   12'd2576:circle_limit=7'd100;
   12'd2577:circle_limit=7'd100;
   12'd2578:circle_limit=7'd99;
   12'd2579:circle_limit=7'd99;
   12'd2580:circle_limit=7'd98;
   12'd2581:circle_limit=7'd98;
   12'd2582:circle_limit=7'd97;
   12'd2583:circle_limit=7'd96;
   12'd2584:circle_limit=7'd96;
   12'd2585:circle_limit=7'd95;
   12'd2586:circle_limit=7'd94;
   12'd2587:circle_limit=7'd93;
   12'd2588:circle_limit=7'd92;
   12'd2589:circle_limit=7'd91;
   12'd2590:circle_limit=7'd90;
   12'd2591:circle_limit=7'd89;
   12'd2592:circle_limit=7'd88;
   12'd2593:circle_limit=7'd86;
   12'd2594:circle_limit=7'd85;
   12'd2595:circle_limit=7'd83;
   12'd2596:circle_limit=7'd81;
   12'd2597:circle_limit=7'd79;
   12'd2598:circle_limit=7'd76;
   12'd2599:circle_limit=7'd72;
   12'd2600:circle_limit=7'd64;
   12'd2624:circle_limit=7'd105;
   12'd2625:circle_limit=7'd104;
   12'd2626:circle_limit=7'd104;
   12'd2627:circle_limit=7'd104;
   12'd2628:circle_limit=7'd104;
   12'd2629:circle_limit=7'd104;
   12'd2630:circle_limit=7'd104;
   12'd2631:circle_limit=7'd104;
   12'd2632:circle_limit=7'd104;
   12'd2633:circle_limit=7'd104;
   12'd2634:circle_limit=7'd103;
   12'd2635:circle_limit=7'd103;
   12'd2636:circle_limit=7'd103;
   12'd2637:circle_limit=7'd102;
   12'd2638:circle_limit=7'd102;
   12'd2639:circle_limit=7'd102;
   12'd2640:circle_limit=7'd101;
   12'd2641:circle_limit=7'd101;
   12'd2642:circle_limit=7'd100;
   12'd2643:circle_limit=7'd100;
   12'd2644:circle_limit=7'd99;
   12'd2645:circle_limit=7'd99;
   12'd2646:circle_limit=7'd98;
   12'd2647:circle_limit=7'd97;
   12'd2648:circle_limit=7'd97;
   12'd2649:circle_limit=7'd96;
   12'd2650:circle_limit=7'd95;
   12'd2651:circle_limit=7'd94;
   12'd2652:circle_limit=7'd93;
   12'd2653:circle_limit=7'd92;
   12'd2654:circle_limit=7'd91;
   12'd2655:circle_limit=7'd90;
   12'd2656:circle_limit=7'd89;
   12'd2657:circle_limit=7'd88;
   12'd2658:circle_limit=7'd86;
   12'd2659:circle_limit=7'd85;
   12'd2660:circle_limit=7'd83;
   12'd2661:circle_limit=7'd81;
   12'd2662:circle_limit=7'd79;
   12'd2663:circle_limit=7'd76;
   12'd2664:circle_limit=7'd73;
   12'd2665:circle_limit=7'd64;
   12'd2688:circle_limit=7'd106;
   12'd2689:circle_limit=7'd105;
   12'd2690:circle_limit=7'd105;
   12'd2691:circle_limit=7'd105;
   12'd2692:circle_limit=7'd105;
   12'd2693:circle_limit=7'd105;
   12'd2694:circle_limit=7'd105;
   12'd2695:circle_limit=7'd105;
   12'd2696:circle_limit=7'd105;
   12'd2697:circle_limit=7'd105;
   12'd2698:circle_limit=7'd104;
   12'd2699:circle_limit=7'd104;
   12'd2700:circle_limit=7'd104;
   12'd2701:circle_limit=7'd103;
   12'd2702:circle_limit=7'd103;
   12'd2703:circle_limit=7'd103;
   12'd2704:circle_limit=7'd102;
   12'd2705:circle_limit=7'd102;
   12'd2706:circle_limit=7'd101;
   12'd2707:circle_limit=7'd101;
   12'd2708:circle_limit=7'd100;
   12'd2709:circle_limit=7'd100;
   12'd2710:circle_limit=7'd99;
   12'd2711:circle_limit=7'd99;
   12'd2712:circle_limit=7'd98;
   12'd2713:circle_limit=7'd97;
   12'd2714:circle_limit=7'd96;
   12'd2715:circle_limit=7'd96;
   12'd2716:circle_limit=7'd95;
   12'd2717:circle_limit=7'd94;
   12'd2718:circle_limit=7'd93;
   12'd2719:circle_limit=7'd92;
   12'd2720:circle_limit=7'd91;
   12'd2721:circle_limit=7'd89;
   12'd2722:circle_limit=7'd88;
   12'd2723:circle_limit=7'd87;
   12'd2724:circle_limit=7'd85;
   12'd2725:circle_limit=7'd83;
   12'd2726:circle_limit=7'd81;
   12'd2727:circle_limit=7'd79;
   12'd2728:circle_limit=7'd76;
   12'd2729:circle_limit=7'd73;
   12'd2730:circle_limit=7'd64;
   12'd2752:circle_limit=7'd107;
   12'd2753:circle_limit=7'd106;
   12'd2754:circle_limit=7'd106;
   12'd2755:circle_limit=7'd106;
   12'd2756:circle_limit=7'd106;
   12'd2757:circle_limit=7'd106;
   12'd2758:circle_limit=7'd106;
   12'd2759:circle_limit=7'd106;
   12'd2760:circle_limit=7'd106;
   12'd2761:circle_limit=7'd106;
   12'd2762:circle_limit=7'd105;
   12'd2763:circle_limit=7'd105;
   12'd2764:circle_limit=7'd105;
   12'd2765:circle_limit=7'd104;
   12'd2766:circle_limit=7'd104;
   12'd2767:circle_limit=7'd104;
   12'd2768:circle_limit=7'd103;
   12'd2769:circle_limit=7'd103;
   12'd2770:circle_limit=7'd103;
   12'd2771:circle_limit=7'd102;
   12'd2772:circle_limit=7'd102;
   12'd2773:circle_limit=7'd101;
   12'd2774:circle_limit=7'd100;
   12'd2775:circle_limit=7'd100;
   12'd2776:circle_limit=7'd99;
   12'd2777:circle_limit=7'd98;
   12'd2778:circle_limit=7'd98;
   12'd2779:circle_limit=7'd97;
   12'd2780:circle_limit=7'd96;
   12'd2781:circle_limit=7'd95;
   12'd2782:circle_limit=7'd94;
   12'd2783:circle_limit=7'd93;
   12'd2784:circle_limit=7'd92;
   12'd2785:circle_limit=7'd91;
   12'd2786:circle_limit=7'd90;
   12'd2787:circle_limit=7'd88;
   12'd2788:circle_limit=7'd87;
   12'd2789:circle_limit=7'd85;
   12'd2790:circle_limit=7'd84;
   12'd2791:circle_limit=7'd82;
   12'd2792:circle_limit=7'd79;
   12'd2793:circle_limit=7'd76;
   12'd2794:circle_limit=7'd73;
   12'd2795:circle_limit=7'd64;
   12'd2816:circle_limit=7'd108;
   12'd2817:circle_limit=7'd107;
   12'd2818:circle_limit=7'd107;
   12'd2819:circle_limit=7'd107;
   12'd2820:circle_limit=7'd107;
   12'd2821:circle_limit=7'd107;
   12'd2822:circle_limit=7'd107;
   12'd2823:circle_limit=7'd107;
   12'd2824:circle_limit=7'd107;
   12'd2825:circle_limit=7'd107;
   12'd2826:circle_limit=7'd106;
   12'd2827:circle_limit=7'd106;
   12'd2828:circle_limit=7'd106;
   12'd2829:circle_limit=7'd106;
   12'd2830:circle_limit=7'd105;
   12'd2831:circle_limit=7'd105;
   12'd2832:circle_limit=7'd104;
   12'd2833:circle_limit=7'd104;
   12'd2834:circle_limit=7'd104;
   12'd2835:circle_limit=7'd103;
   12'd2836:circle_limit=7'd103;
   12'd2837:circle_limit=7'd102;
   12'd2838:circle_limit=7'd102;
   12'd2839:circle_limit=7'd101;
   12'd2840:circle_limit=7'd100;
   12'd2841:circle_limit=7'd100;
   12'd2842:circle_limit=7'd99;
   12'd2843:circle_limit=7'd98;
   12'd2844:circle_limit=7'd97;
   12'd2845:circle_limit=7'd97;
   12'd2846:circle_limit=7'd96;
   12'd2847:circle_limit=7'd95;
   12'd2848:circle_limit=7'd94;
   12'd2849:circle_limit=7'd93;
   12'd2850:circle_limit=7'd91;
   12'd2851:circle_limit=7'd90;
   12'd2852:circle_limit=7'd89;
   12'd2853:circle_limit=7'd87;
   12'd2854:circle_limit=7'd86;
   12'd2855:circle_limit=7'd84;
   12'd2856:circle_limit=7'd82;
   12'd2857:circle_limit=7'd79;
   12'd2858:circle_limit=7'd77;
   12'd2859:circle_limit=7'd73;
   12'd2860:circle_limit=7'd64;
   12'd2880:circle_limit=7'd109;
   12'd2881:circle_limit=7'd108;
   12'd2882:circle_limit=7'd108;
   12'd2883:circle_limit=7'd108;
   12'd2884:circle_limit=7'd108;
   12'd2885:circle_limit=7'd108;
   12'd2886:circle_limit=7'd108;
   12'd2887:circle_limit=7'd108;
   12'd2888:circle_limit=7'd108;
   12'd2889:circle_limit=7'd108;
   12'd2890:circle_limit=7'd107;
   12'd2891:circle_limit=7'd107;
   12'd2892:circle_limit=7'd107;
   12'd2893:circle_limit=7'd107;
   12'd2894:circle_limit=7'd106;
   12'd2895:circle_limit=7'd106;
   12'd2896:circle_limit=7'd106;
   12'd2897:circle_limit=7'd105;
   12'd2898:circle_limit=7'd105;
   12'd2899:circle_limit=7'd104;
   12'd2900:circle_limit=7'd104;
   12'd2901:circle_limit=7'd103;
   12'd2902:circle_limit=7'd103;
   12'd2903:circle_limit=7'd102;
   12'd2904:circle_limit=7'd102;
   12'd2905:circle_limit=7'd101;
   12'd2906:circle_limit=7'd100;
   12'd2907:circle_limit=7'd100;
   12'd2908:circle_limit=7'd99;
   12'd2909:circle_limit=7'd98;
   12'd2910:circle_limit=7'd97;
   12'd2911:circle_limit=7'd96;
   12'd2912:circle_limit=7'd95;
   12'd2913:circle_limit=7'd94;
   12'd2914:circle_limit=7'd93;
   12'd2915:circle_limit=7'd92;
   12'd2916:circle_limit=7'd91;
   12'd2917:circle_limit=7'd89;
   12'd2918:circle_limit=7'd88;
   12'd2919:circle_limit=7'd86;
   12'd2920:circle_limit=7'd84;
   12'd2921:circle_limit=7'd82;
   12'd2922:circle_limit=7'd80;
   12'd2923:circle_limit=7'd77;
   12'd2924:circle_limit=7'd73;
   12'd2925:circle_limit=7'd64;
   12'd2944:circle_limit=7'd110;
   12'd2945:circle_limit=7'd109;
   12'd2946:circle_limit=7'd109;
   12'd2947:circle_limit=7'd109;
   12'd2948:circle_limit=7'd109;
   12'd2949:circle_limit=7'd109;
   12'd2950:circle_limit=7'd109;
   12'd2951:circle_limit=7'd109;
   12'd2952:circle_limit=7'd109;
   12'd2953:circle_limit=7'd109;
   12'd2954:circle_limit=7'd108;
   12'd2955:circle_limit=7'd108;
   12'd2956:circle_limit=7'd108;
   12'd2957:circle_limit=7'd108;
   12'd2958:circle_limit=7'd107;
   12'd2959:circle_limit=7'd107;
   12'd2960:circle_limit=7'd107;
   12'd2961:circle_limit=7'd106;
   12'd2962:circle_limit=7'd106;
   12'd2963:circle_limit=7'd105;
   12'd2964:circle_limit=7'd105;
   12'd2965:circle_limit=7'd104;
   12'd2966:circle_limit=7'd104;
   12'd2967:circle_limit=7'd103;
   12'd2968:circle_limit=7'd103;
   12'd2969:circle_limit=7'd102;
   12'd2970:circle_limit=7'd101;
   12'd2971:circle_limit=7'd101;
   12'd2972:circle_limit=7'd100;
   12'd2973:circle_limit=7'd99;
   12'd2974:circle_limit=7'd98;
   12'd2975:circle_limit=7'd97;
   12'd2976:circle_limit=7'd97;
   12'd2977:circle_limit=7'd96;
   12'd2978:circle_limit=7'd94;
   12'd2979:circle_limit=7'd93;
   12'd2980:circle_limit=7'd92;
   12'd2981:circle_limit=7'd91;
   12'd2982:circle_limit=7'd89;
   12'd2983:circle_limit=7'd88;
   12'd2984:circle_limit=7'd86;
   12'd2985:circle_limit=7'd84;
   12'd2986:circle_limit=7'd82;
   12'd2987:circle_limit=7'd80;
   12'd2988:circle_limit=7'd77;
   12'd2989:circle_limit=7'd73;
   12'd2990:circle_limit=7'd64;
   12'd3008:circle_limit=7'd111;
   12'd3009:circle_limit=7'd110;
   12'd3010:circle_limit=7'd110;
   12'd3011:circle_limit=7'd110;
   12'd3012:circle_limit=7'd110;
   12'd3013:circle_limit=7'd110;
   12'd3014:circle_limit=7'd110;
   12'd3015:circle_limit=7'd110;
   12'd3016:circle_limit=7'd110;
   12'd3017:circle_limit=7'd110;
   12'd3018:circle_limit=7'd109;
   12'd3019:circle_limit=7'd109;
   12'd3020:circle_limit=7'd109;
   12'd3021:circle_limit=7'd109;
   12'd3022:circle_limit=7'd108;
   12'd3023:circle_limit=7'd108;
   12'd3024:circle_limit=7'd108;
   12'd3025:circle_limit=7'd107;
   12'd3026:circle_limit=7'd107;
   12'd3027:circle_limit=7'd106;
   12'd3028:circle_limit=7'd106;
   12'd3029:circle_limit=7'd106;
   12'd3030:circle_limit=7'd105;
   12'd3031:circle_limit=7'd104;
   12'd3032:circle_limit=7'd104;
   12'd3033:circle_limit=7'd103;
   12'd3034:circle_limit=7'd103;
   12'd3035:circle_limit=7'd102;
   12'd3036:circle_limit=7'd101;
   12'd3037:circle_limit=7'd100;
   12'd3038:circle_limit=7'd100;
   12'd3039:circle_limit=7'd99;
   12'd3040:circle_limit=7'd98;
   12'd3041:circle_limit=7'd97;
   12'd3042:circle_limit=7'd96;
   12'd3043:circle_limit=7'd95;
   12'd3044:circle_limit=7'd94;
   12'd3045:circle_limit=7'd92;
   12'd3046:circle_limit=7'd91;
   12'd3047:circle_limit=7'd90;
   12'd3048:circle_limit=7'd88;
   12'd3049:circle_limit=7'd86;
   12'd3050:circle_limit=7'd85;
   12'd3051:circle_limit=7'd82;
   12'd3052:circle_limit=7'd80;
   12'd3053:circle_limit=7'd77;
   12'd3054:circle_limit=7'd73;
   12'd3055:circle_limit=7'd64;
   12'd3072:circle_limit=7'd112;
   12'd3073:circle_limit=7'd111;
   12'd3074:circle_limit=7'd111;
   12'd3075:circle_limit=7'd111;
   12'd3076:circle_limit=7'd111;
   12'd3077:circle_limit=7'd111;
   12'd3078:circle_limit=7'd111;
   12'd3079:circle_limit=7'd111;
   12'd3080:circle_limit=7'd111;
   12'd3081:circle_limit=7'd111;
   12'd3082:circle_limit=7'd110;
   12'd3083:circle_limit=7'd110;
   12'd3084:circle_limit=7'd110;
   12'd3085:circle_limit=7'd110;
   12'd3086:circle_limit=7'd109;
   12'd3087:circle_limit=7'd109;
   12'd3088:circle_limit=7'd109;
   12'd3089:circle_limit=7'd108;
   12'd3090:circle_limit=7'd108;
   12'd3091:circle_limit=7'd108;
   12'd3092:circle_limit=7'd107;
   12'd3093:circle_limit=7'd107;
   12'd3094:circle_limit=7'd106;
   12'd3095:circle_limit=7'd106;
   12'd3096:circle_limit=7'd105;
   12'd3097:circle_limit=7'd104;
   12'd3098:circle_limit=7'd104;
   12'd3099:circle_limit=7'd103;
   12'd3100:circle_limit=7'd102;
   12'd3101:circle_limit=7'd102;
   12'd3102:circle_limit=7'd101;
   12'd3103:circle_limit=7'd100;
   12'd3104:circle_limit=7'd99;
   12'd3105:circle_limit=7'd98;
   12'd3106:circle_limit=7'd97;
   12'd3107:circle_limit=7'd96;
   12'd3108:circle_limit=7'd95;
   12'd3109:circle_limit=7'd94;
   12'd3110:circle_limit=7'd93;
   12'd3111:circle_limit=7'd91;
   12'd3112:circle_limit=7'd90;
   12'd3113:circle_limit=7'd88;
   12'd3114:circle_limit=7'd87;
   12'd3115:circle_limit=7'd85;
   12'd3116:circle_limit=7'd83;
   12'd3117:circle_limit=7'd80;
   12'd3118:circle_limit=7'd77;
   12'd3119:circle_limit=7'd73;
   12'd3120:circle_limit=7'd64;
   12'd3136:circle_limit=7'd113;
   12'd3137:circle_limit=7'd112;
   12'd3138:circle_limit=7'd112;
   12'd3139:circle_limit=7'd112;
   12'd3140:circle_limit=7'd112;
   12'd3141:circle_limit=7'd112;
   12'd3142:circle_limit=7'd112;
   12'd3143:circle_limit=7'd112;
   12'd3144:circle_limit=7'd112;
   12'd3145:circle_limit=7'd112;
   12'd3146:circle_limit=7'd111;
   12'd3147:circle_limit=7'd111;
   12'd3148:circle_limit=7'd111;
   12'd3149:circle_limit=7'd111;
   12'd3150:circle_limit=7'd110;
   12'd3151:circle_limit=7'd110;
   12'd3152:circle_limit=7'd110;
   12'd3153:circle_limit=7'd109;
   12'd3154:circle_limit=7'd109;
   12'd3155:circle_limit=7'd109;
   12'd3156:circle_limit=7'd108;
   12'd3157:circle_limit=7'd108;
   12'd3158:circle_limit=7'd107;
   12'd3159:circle_limit=7'd107;
   12'd3160:circle_limit=7'd106;
   12'd3161:circle_limit=7'd106;
   12'd3162:circle_limit=7'd105;
   12'd3163:circle_limit=7'd104;
   12'd3164:circle_limit=7'd104;
   12'd3165:circle_limit=7'd103;
   12'd3166:circle_limit=7'd102;
   12'd3167:circle_limit=7'd101;
   12'd3168:circle_limit=7'd101;
   12'd3169:circle_limit=7'd100;
   12'd3170:circle_limit=7'd99;
   12'd3171:circle_limit=7'd98;
   12'd3172:circle_limit=7'd97;
   12'd3173:circle_limit=7'd96;
   12'd3174:circle_limit=7'd94;
   12'd3175:circle_limit=7'd93;
   12'd3176:circle_limit=7'd92;
   12'd3177:circle_limit=7'd90;
   12'd3178:circle_limit=7'd89;
   12'd3179:circle_limit=7'd87;
   12'd3180:circle_limit=7'd85;
   12'd3181:circle_limit=7'd83;
   12'd3182:circle_limit=7'd80;
   12'd3183:circle_limit=7'd77;
   12'd3184:circle_limit=7'd73;
   12'd3185:circle_limit=7'd64;
   12'd3200:circle_limit=7'd114;
   12'd3201:circle_limit=7'd113;
   12'd3202:circle_limit=7'd113;
   12'd3203:circle_limit=7'd113;
   12'd3204:circle_limit=7'd113;
   12'd3205:circle_limit=7'd113;
   12'd3206:circle_limit=7'd113;
   12'd3207:circle_limit=7'd113;
   12'd3208:circle_limit=7'd113;
   12'd3209:circle_limit=7'd113;
   12'd3210:circle_limit=7'd112;
   12'd3211:circle_limit=7'd112;
   12'd3212:circle_limit=7'd112;
   12'd3213:circle_limit=7'd112;
   12'd3214:circle_limit=7'd112;
   12'd3215:circle_limit=7'd111;
   12'd3216:circle_limit=7'd111;
   12'd3217:circle_limit=7'd111;
   12'd3218:circle_limit=7'd110;
   12'd3219:circle_limit=7'd110;
   12'd3220:circle_limit=7'd109;
   12'd3221:circle_limit=7'd109;
   12'd3222:circle_limit=7'd108;
   12'd3223:circle_limit=7'd108;
   12'd3224:circle_limit=7'd107;
   12'd3225:circle_limit=7'd107;
   12'd3226:circle_limit=7'd106;
   12'd3227:circle_limit=7'd106;
   12'd3228:circle_limit=7'd105;
   12'd3229:circle_limit=7'd104;
   12'd3230:circle_limit=7'd104;
   12'd3231:circle_limit=7'd103;
   12'd3232:circle_limit=7'd102;
   12'd3233:circle_limit=7'd101;
   12'd3234:circle_limit=7'd100;
   12'd3235:circle_limit=7'd99;
   12'd3236:circle_limit=7'd98;
   12'd3237:circle_limit=7'd97;
   12'd3238:circle_limit=7'd96;
   12'd3239:circle_limit=7'd95;
   12'd3240:circle_limit=7'd94;
   12'd3241:circle_limit=7'd92;
   12'd3242:circle_limit=7'd91;
   12'd3243:circle_limit=7'd89;
   12'd3244:circle_limit=7'd87;
   12'd3245:circle_limit=7'd85;
   12'd3246:circle_limit=7'd83;
   12'd3247:circle_limit=7'd81;
   12'd3248:circle_limit=7'd78;
   12'd3249:circle_limit=7'd73;
   12'd3250:circle_limit=7'd64;
   12'd3264:circle_limit=7'd115;
   12'd3265:circle_limit=7'd114;
   12'd3266:circle_limit=7'd114;
   12'd3267:circle_limit=7'd114;
   12'd3268:circle_limit=7'd114;
   12'd3269:circle_limit=7'd114;
   12'd3270:circle_limit=7'd114;
   12'd3271:circle_limit=7'd114;
   12'd3272:circle_limit=7'd114;
   12'd3273:circle_limit=7'd114;
   12'd3274:circle_limit=7'd114;
   12'd3275:circle_limit=7'd113;
   12'd3276:circle_limit=7'd113;
   12'd3277:circle_limit=7'd113;
   12'd3278:circle_limit=7'd113;
   12'd3279:circle_limit=7'd112;
   12'd3280:circle_limit=7'd112;
   12'd3281:circle_limit=7'd112;
   12'd3282:circle_limit=7'd111;
   12'd3283:circle_limit=7'd111;
   12'd3284:circle_limit=7'd110;
   12'd3285:circle_limit=7'd110;
   12'd3286:circle_limit=7'd110;
   12'd3287:circle_limit=7'd109;
   12'd3288:circle_limit=7'd109;
   12'd3289:circle_limit=7'd108;
   12'd3290:circle_limit=7'd107;
   12'd3291:circle_limit=7'd107;
   12'd3292:circle_limit=7'd106;
   12'd3293:circle_limit=7'd105;
   12'd3294:circle_limit=7'd105;
   12'd3295:circle_limit=7'd104;
   12'd3296:circle_limit=7'd103;
   12'd3297:circle_limit=7'd102;
   12'd3298:circle_limit=7'd102;
   12'd3299:circle_limit=7'd101;
   12'd3300:circle_limit=7'd100;
   12'd3301:circle_limit=7'd99;
   12'd3302:circle_limit=7'd98;
   12'd3303:circle_limit=7'd96;
   12'd3304:circle_limit=7'd95;
   12'd3305:circle_limit=7'd94;
   12'd3306:circle_limit=7'd92;
   12'd3307:circle_limit=7'd91;
   12'd3308:circle_limit=7'd89;
   12'd3309:circle_limit=7'd88;
   12'd3310:circle_limit=7'd86;
   12'd3311:circle_limit=7'd83;
   12'd3312:circle_limit=7'd81;
   12'd3313:circle_limit=7'd78;
   12'd3314:circle_limit=7'd74;
   12'd3315:circle_limit=7'd64;
   12'd3328:circle_limit=7'd116;
   12'd3329:circle_limit=7'd115;
   12'd3330:circle_limit=7'd115;
   12'd3331:circle_limit=7'd115;
   12'd3332:circle_limit=7'd115;
   12'd3333:circle_limit=7'd115;
   12'd3334:circle_limit=7'd115;
   12'd3335:circle_limit=7'd115;
   12'd3336:circle_limit=7'd115;
   12'd3337:circle_limit=7'd115;
   12'd3338:circle_limit=7'd115;
   12'd3339:circle_limit=7'd114;
   12'd3340:circle_limit=7'd114;
   12'd3341:circle_limit=7'd114;
   12'd3342:circle_limit=7'd114;
   12'd3343:circle_limit=7'd113;
   12'd3344:circle_limit=7'd113;
   12'd3345:circle_limit=7'd113;
   12'd3346:circle_limit=7'd112;
   12'd3347:circle_limit=7'd112;
   12'd3348:circle_limit=7'd112;
   12'd3349:circle_limit=7'd111;
   12'd3350:circle_limit=7'd111;
   12'd3351:circle_limit=7'd110;
   12'd3352:circle_limit=7'd110;
   12'd3353:circle_limit=7'd109;
   12'd3354:circle_limit=7'd109;
   12'd3355:circle_limit=7'd108;
   12'd3356:circle_limit=7'd107;
   12'd3357:circle_limit=7'd107;
   12'd3358:circle_limit=7'd106;
   12'd3359:circle_limit=7'd105;
   12'd3360:circle_limit=7'd104;
   12'd3361:circle_limit=7'd104;
   12'd3362:circle_limit=7'd103;
   12'd3363:circle_limit=7'd102;
   12'd3364:circle_limit=7'd101;
   12'd3365:circle_limit=7'd100;
   12'd3366:circle_limit=7'd99;
   12'd3367:circle_limit=7'd98;
   12'd3368:circle_limit=7'd97;
   12'd3369:circle_limit=7'd95;
   12'd3370:circle_limit=7'd94;
   12'd3371:circle_limit=7'd93;
   12'd3372:circle_limit=7'd91;
   12'd3373:circle_limit=7'd90;
   12'd3374:circle_limit=7'd88;
   12'd3375:circle_limit=7'd86;
   12'd3376:circle_limit=7'd84;
   12'd3377:circle_limit=7'd81;
   12'd3378:circle_limit=7'd78;
   12'd3379:circle_limit=7'd74;
   12'd3380:circle_limit=7'd64;
   12'd3392:circle_limit=7'd117;
   12'd3393:circle_limit=7'd116;
   12'd3394:circle_limit=7'd116;
   12'd3395:circle_limit=7'd116;
   12'd3396:circle_limit=7'd116;
   12'd3397:circle_limit=7'd116;
   12'd3398:circle_limit=7'd116;
   12'd3399:circle_limit=7'd116;
   12'd3400:circle_limit=7'd116;
   12'd3401:circle_limit=7'd116;
   12'd3402:circle_limit=7'd116;
   12'd3403:circle_limit=7'd115;
   12'd3404:circle_limit=7'd115;
   12'd3405:circle_limit=7'd115;
   12'd3406:circle_limit=7'd115;
   12'd3407:circle_limit=7'd114;
   12'd3408:circle_limit=7'd114;
   12'd3409:circle_limit=7'd114;
   12'd3410:circle_limit=7'd113;
   12'd3411:circle_limit=7'd113;
   12'd3412:circle_limit=7'd113;
   12'd3413:circle_limit=7'd112;
   12'd3414:circle_limit=7'd112;
   12'd3415:circle_limit=7'd111;
   12'd3416:circle_limit=7'd111;
   12'd3417:circle_limit=7'd110;
   12'd3418:circle_limit=7'd110;
   12'd3419:circle_limit=7'd109;
   12'd3420:circle_limit=7'd109;
   12'd3421:circle_limit=7'd108;
   12'd3422:circle_limit=7'd107;
   12'd3423:circle_limit=7'd106;
   12'd3424:circle_limit=7'd106;
   12'd3425:circle_limit=7'd105;
   12'd3426:circle_limit=7'd104;
   12'd3427:circle_limit=7'd103;
   12'd3428:circle_limit=7'd102;
   12'd3429:circle_limit=7'd101;
   12'd3430:circle_limit=7'd100;
   12'd3431:circle_limit=7'd99;
   12'd3432:circle_limit=7'd98;
   12'd3433:circle_limit=7'd97;
   12'd3434:circle_limit=7'd96;
   12'd3435:circle_limit=7'd94;
   12'd3436:circle_limit=7'd93;
   12'd3437:circle_limit=7'd92;
   12'd3438:circle_limit=7'd90;
   12'd3439:circle_limit=7'd88;
   12'd3440:circle_limit=7'd86;
   12'd3441:circle_limit=7'd84;
   12'd3442:circle_limit=7'd81;
   12'd3443:circle_limit=7'd78;
   12'd3444:circle_limit=7'd74;
   12'd3445:circle_limit=7'd64;
   12'd3456:circle_limit=7'd118;
   12'd3457:circle_limit=7'd117;
   12'd3458:circle_limit=7'd117;
   12'd3459:circle_limit=7'd117;
   12'd3460:circle_limit=7'd117;
   12'd3461:circle_limit=7'd117;
   12'd3462:circle_limit=7'd117;
   12'd3463:circle_limit=7'd117;
   12'd3464:circle_limit=7'd117;
   12'd3465:circle_limit=7'd117;
   12'd3466:circle_limit=7'd117;
   12'd3467:circle_limit=7'd116;
   12'd3468:circle_limit=7'd116;
   12'd3469:circle_limit=7'd116;
   12'd3470:circle_limit=7'd116;
   12'd3471:circle_limit=7'd115;
   12'd3472:circle_limit=7'd115;
   12'd3473:circle_limit=7'd115;
   12'd3474:circle_limit=7'd114;
   12'd3475:circle_limit=7'd114;
   12'd3476:circle_limit=7'd114;
   12'd3477:circle_limit=7'd113;
   12'd3478:circle_limit=7'd113;
   12'd3479:circle_limit=7'd112;
   12'd3480:circle_limit=7'd112;
   12'd3481:circle_limit=7'd111;
   12'd3482:circle_limit=7'd111;
   12'd3483:circle_limit=7'd110;
   12'd3484:circle_limit=7'd110;
   12'd3485:circle_limit=7'd109;
   12'd3486:circle_limit=7'd108;
   12'd3487:circle_limit=7'd108;
   12'd3488:circle_limit=7'd107;
   12'd3489:circle_limit=7'd106;
   12'd3490:circle_limit=7'd105;
   12'd3491:circle_limit=7'd105;
   12'd3492:circle_limit=7'd104;
   12'd3493:circle_limit=7'd103;
   12'd3494:circle_limit=7'd102;
   12'd3495:circle_limit=7'd101;
   12'd3496:circle_limit=7'd100;
   12'd3497:circle_limit=7'd99;
   12'd3498:circle_limit=7'd97;
   12'd3499:circle_limit=7'd96;
   12'd3500:circle_limit=7'd95;
   12'd3501:circle_limit=7'd93;
   12'd3502:circle_limit=7'd92;
   12'd3503:circle_limit=7'd90;
   12'd3504:circle_limit=7'd88;
   12'd3505:circle_limit=7'd86;
   12'd3506:circle_limit=7'd84;
   12'd3507:circle_limit=7'd81;
   12'd3508:circle_limit=7'd78;
   12'd3509:circle_limit=7'd74;
   12'd3510:circle_limit=7'd64;
   12'd3520:circle_limit=7'd119;
   12'd3521:circle_limit=7'd118;
   12'd3522:circle_limit=7'd118;
   12'd3523:circle_limit=7'd118;
   12'd3524:circle_limit=7'd118;
   12'd3525:circle_limit=7'd118;
   12'd3526:circle_limit=7'd118;
   12'd3527:circle_limit=7'd118;
   12'd3528:circle_limit=7'd118;
   12'd3529:circle_limit=7'd118;
   12'd3530:circle_limit=7'd118;
   12'd3531:circle_limit=7'd117;
   12'd3532:circle_limit=7'd117;
   12'd3533:circle_limit=7'd117;
   12'd3534:circle_limit=7'd117;
   12'd3535:circle_limit=7'd116;
   12'd3536:circle_limit=7'd116;
   12'd3537:circle_limit=7'd116;
   12'd3538:circle_limit=7'd115;
   12'd3539:circle_limit=7'd115;
   12'd3540:circle_limit=7'd115;
   12'd3541:circle_limit=7'd114;
   12'd3542:circle_limit=7'd114;
   12'd3543:circle_limit=7'd113;
   12'd3544:circle_limit=7'd113;
   12'd3545:circle_limit=7'd112;
   12'd3546:circle_limit=7'd112;
   12'd3547:circle_limit=7'd111;
   12'd3548:circle_limit=7'd111;
   12'd3549:circle_limit=7'd110;
   12'd3550:circle_limit=7'd110;
   12'd3551:circle_limit=7'd109;
   12'd3552:circle_limit=7'd108;
   12'd3553:circle_limit=7'd108;
   12'd3554:circle_limit=7'd107;
   12'd3555:circle_limit=7'd106;
   12'd3556:circle_limit=7'd105;
   12'd3557:circle_limit=7'd104;
   12'd3558:circle_limit=7'd103;
   12'd3559:circle_limit=7'd102;
   12'd3560:circle_limit=7'd101;
   12'd3561:circle_limit=7'd100;
   12'd3562:circle_limit=7'd99;
   12'd3563:circle_limit=7'd98;
   12'd3564:circle_limit=7'd97;
   12'd3565:circle_limit=7'd95;
   12'd3566:circle_limit=7'd94;
   12'd3567:circle_limit=7'd92;
   12'd3568:circle_limit=7'd90;
   12'd3569:circle_limit=7'd88;
   12'd3570:circle_limit=7'd86;
   12'd3571:circle_limit=7'd84;
   12'd3572:circle_limit=7'd81;
   12'd3573:circle_limit=7'd78;
   12'd3574:circle_limit=7'd74;
   12'd3575:circle_limit=7'd64;
   12'd3584:circle_limit=7'd120;
   12'd3585:circle_limit=7'd119;
   12'd3586:circle_limit=7'd119;
   12'd3587:circle_limit=7'd119;
   12'd3588:circle_limit=7'd119;
   12'd3589:circle_limit=7'd119;
   12'd3590:circle_limit=7'd119;
   12'd3591:circle_limit=7'd119;
   12'd3592:circle_limit=7'd119;
   12'd3593:circle_limit=7'd119;
   12'd3594:circle_limit=7'd119;
   12'd3595:circle_limit=7'd118;
   12'd3596:circle_limit=7'd118;
   12'd3597:circle_limit=7'd118;
   12'd3598:circle_limit=7'd118;
   12'd3599:circle_limit=7'd117;
   12'd3600:circle_limit=7'd117;
   12'd3601:circle_limit=7'd117;
   12'd3602:circle_limit=7'd117;
   12'd3603:circle_limit=7'd116;
   12'd3604:circle_limit=7'd116;
   12'd3605:circle_limit=7'd115;
   12'd3606:circle_limit=7'd115;
   12'd3607:circle_limit=7'd115;
   12'd3608:circle_limit=7'd114;
   12'd3609:circle_limit=7'd114;
   12'd3610:circle_limit=7'd113;
   12'd3611:circle_limit=7'd113;
   12'd3612:circle_limit=7'd112;
   12'd3613:circle_limit=7'd111;
   12'd3614:circle_limit=7'd111;
   12'd3615:circle_limit=7'd110;
   12'd3616:circle_limit=7'd109;
   12'd3617:circle_limit=7'd109;
   12'd3618:circle_limit=7'd108;
   12'd3619:circle_limit=7'd107;
   12'd3620:circle_limit=7'd106;
   12'd3621:circle_limit=7'd106;
   12'd3622:circle_limit=7'd105;
   12'd3623:circle_limit=7'd104;
   12'd3624:circle_limit=7'd103;
   12'd3625:circle_limit=7'd102;
   12'd3626:circle_limit=7'd101;
   12'd3627:circle_limit=7'd99;
   12'd3628:circle_limit=7'd98;
   12'd3629:circle_limit=7'd97;
   12'd3630:circle_limit=7'd95;
   12'd3631:circle_limit=7'd94;
   12'd3632:circle_limit=7'd92;
   12'd3633:circle_limit=7'd91;
   12'd3634:circle_limit=7'd89;
   12'd3635:circle_limit=7'd87;
   12'd3636:circle_limit=7'd84;
   12'd3637:circle_limit=7'd82;
   12'd3638:circle_limit=7'd78;
   12'd3639:circle_limit=7'd74;
   12'd3640:circle_limit=7'd64;
   12'd3648:circle_limit=7'd121;
   12'd3649:circle_limit=7'd120;
   12'd3650:circle_limit=7'd120;
   12'd3651:circle_limit=7'd120;
   12'd3652:circle_limit=7'd120;
   12'd3653:circle_limit=7'd120;
   12'd3654:circle_limit=7'd120;
   12'd3655:circle_limit=7'd120;
   12'd3656:circle_limit=7'd120;
   12'd3657:circle_limit=7'd120;
   12'd3658:circle_limit=7'd120;
   12'd3659:circle_limit=7'd119;
   12'd3660:circle_limit=7'd119;
   12'd3661:circle_limit=7'd119;
   12'd3662:circle_limit=7'd119;
   12'd3663:circle_limit=7'd118;
   12'd3664:circle_limit=7'd118;
   12'd3665:circle_limit=7'd118;
   12'd3666:circle_limit=7'd118;
   12'd3667:circle_limit=7'd117;
   12'd3668:circle_limit=7'd117;
   12'd3669:circle_limit=7'd116;
   12'd3670:circle_limit=7'd116;
   12'd3671:circle_limit=7'd116;
   12'd3672:circle_limit=7'd115;
   12'd3673:circle_limit=7'd115;
   12'd3674:circle_limit=7'd114;
   12'd3675:circle_limit=7'd114;
   12'd3676:circle_limit=7'd113;
   12'd3677:circle_limit=7'd113;
   12'd3678:circle_limit=7'd112;
   12'd3679:circle_limit=7'd111;
   12'd3680:circle_limit=7'd111;
   12'd3681:circle_limit=7'd110;
   12'd3682:circle_limit=7'd109;
   12'd3683:circle_limit=7'd108;
   12'd3684:circle_limit=7'd108;
   12'd3685:circle_limit=7'd107;
   12'd3686:circle_limit=7'd106;
   12'd3687:circle_limit=7'd105;
   12'd3688:circle_limit=7'd104;
   12'd3689:circle_limit=7'd103;
   12'd3690:circle_limit=7'd102;
   12'd3691:circle_limit=7'd101;
   12'd3692:circle_limit=7'd100;
   12'd3693:circle_limit=7'd98;
   12'd3694:circle_limit=7'd97;
   12'd3695:circle_limit=7'd96;
   12'd3696:circle_limit=7'd94;
   12'd3697:circle_limit=7'd93;
   12'd3698:circle_limit=7'd91;
   12'd3699:circle_limit=7'd89;
   12'd3700:circle_limit=7'd87;
   12'd3701:circle_limit=7'd84;
   12'd3702:circle_limit=7'd82;
   12'd3703:circle_limit=7'd78;
   12'd3704:circle_limit=7'd74;
   12'd3705:circle_limit=7'd64;
   12'd3712:circle_limit=7'd122;
   12'd3713:circle_limit=7'd121;
   12'd3714:circle_limit=7'd121;
   12'd3715:circle_limit=7'd121;
   12'd3716:circle_limit=7'd121;
   12'd3717:circle_limit=7'd121;
   12'd3718:circle_limit=7'd121;
   12'd3719:circle_limit=7'd121;
   12'd3720:circle_limit=7'd121;
   12'd3721:circle_limit=7'd121;
   12'd3722:circle_limit=7'd121;
   12'd3723:circle_limit=7'd120;
   12'd3724:circle_limit=7'd120;
   12'd3725:circle_limit=7'd120;
   12'd3726:circle_limit=7'd120;
   12'd3727:circle_limit=7'd120;
   12'd3728:circle_limit=7'd119;
   12'd3729:circle_limit=7'd119;
   12'd3730:circle_limit=7'd119;
   12'd3731:circle_limit=7'd118;
   12'd3732:circle_limit=7'd118;
   12'd3733:circle_limit=7'd118;
   12'd3734:circle_limit=7'd117;
   12'd3735:circle_limit=7'd117;
   12'd3736:circle_limit=7'd116;
   12'd3737:circle_limit=7'd116;
   12'd3738:circle_limit=7'd115;
   12'd3739:circle_limit=7'd115;
   12'd3740:circle_limit=7'd114;
   12'd3741:circle_limit=7'd114;
   12'd3742:circle_limit=7'd113;
   12'd3743:circle_limit=7'd113;
   12'd3744:circle_limit=7'd112;
   12'd3745:circle_limit=7'd111;
   12'd3746:circle_limit=7'd110;
   12'd3747:circle_limit=7'd110;
   12'd3748:circle_limit=7'd109;
   12'd3749:circle_limit=7'd108;
   12'd3750:circle_limit=7'd107;
   12'd3751:circle_limit=7'd106;
   12'd3752:circle_limit=7'd106;
   12'd3753:circle_limit=7'd105;
   12'd3754:circle_limit=7'd104;
   12'd3755:circle_limit=7'd102;
   12'd3756:circle_limit=7'd101;
   12'd3757:circle_limit=7'd100;
   12'd3758:circle_limit=7'd99;
   12'd3759:circle_limit=7'd97;
   12'd3760:circle_limit=7'd96;
   12'd3761:circle_limit=7'd95;
   12'd3762:circle_limit=7'd93;
   12'd3763:circle_limit=7'd91;
   12'd3764:circle_limit=7'd89;
   12'd3765:circle_limit=7'd87;
   12'd3766:circle_limit=7'd85;
   12'd3767:circle_limit=7'd82;
   12'd3768:circle_limit=7'd79;
   12'd3769:circle_limit=7'd74;
   12'd3770:circle_limit=7'd64;
   12'd3776:circle_limit=7'd123;
   12'd3777:circle_limit=7'd122;
   12'd3778:circle_limit=7'd122;
   12'd3779:circle_limit=7'd122;
   12'd3780:circle_limit=7'd122;
   12'd3781:circle_limit=7'd122;
   12'd3782:circle_limit=7'd122;
   12'd3783:circle_limit=7'd122;
   12'd3784:circle_limit=7'd122;
   12'd3785:circle_limit=7'd122;
   12'd3786:circle_limit=7'd122;
   12'd3787:circle_limit=7'd121;
   12'd3788:circle_limit=7'd121;
   12'd3789:circle_limit=7'd121;
   12'd3790:circle_limit=7'd121;
   12'd3791:circle_limit=7'd121;
   12'd3792:circle_limit=7'd120;
   12'd3793:circle_limit=7'd120;
   12'd3794:circle_limit=7'd120;
   12'd3795:circle_limit=7'd119;
   12'd3796:circle_limit=7'd119;
   12'd3797:circle_limit=7'd119;
   12'd3798:circle_limit=7'd118;
   12'd3799:circle_limit=7'd118;
   12'd3800:circle_limit=7'd117;
   12'd3801:circle_limit=7'd117;
   12'd3802:circle_limit=7'd116;
   12'd3803:circle_limit=7'd116;
   12'd3804:circle_limit=7'd115;
   12'd3805:circle_limit=7'd115;
   12'd3806:circle_limit=7'd114;
   12'd3807:circle_limit=7'd114;
   12'd3808:circle_limit=7'd113;
   12'd3809:circle_limit=7'd112;
   12'd3810:circle_limit=7'd112;
   12'd3811:circle_limit=7'd111;
   12'd3812:circle_limit=7'd110;
   12'd3813:circle_limit=7'd109;
   12'd3814:circle_limit=7'd109;
   12'd3815:circle_limit=7'd108;
   12'd3816:circle_limit=7'd107;
   12'd3817:circle_limit=7'd106;
   12'd3818:circle_limit=7'd105;
   12'd3819:circle_limit=7'd104;
   12'd3820:circle_limit=7'd103;
   12'd3821:circle_limit=7'd102;
   12'd3822:circle_limit=7'd100;
   12'd3823:circle_limit=7'd99;
   12'd3824:circle_limit=7'd98;
   12'd3825:circle_limit=7'd96;
   12'd3826:circle_limit=7'd95;
   12'd3827:circle_limit=7'd93;
   12'd3828:circle_limit=7'd91;
   12'd3829:circle_limit=7'd89;
   12'd3830:circle_limit=7'd87;
   12'd3831:circle_limit=7'd85;
   12'd3832:circle_limit=7'd82;
   12'd3833:circle_limit=7'd79;
   12'd3834:circle_limit=7'd74;
   12'd3835:circle_limit=7'd64;
   12'd3840:circle_limit=7'd124;
   12'd3841:circle_limit=7'd123;
   12'd3842:circle_limit=7'd123;
   12'd3843:circle_limit=7'd123;
   12'd3844:circle_limit=7'd123;
   12'd3845:circle_limit=7'd123;
   12'd3846:circle_limit=7'd123;
   12'd3847:circle_limit=7'd123;
   12'd3848:circle_limit=7'd123;
   12'd3849:circle_limit=7'd123;
   12'd3850:circle_limit=7'd123;
   12'd3851:circle_limit=7'd122;
   12'd3852:circle_limit=7'd122;
   12'd3853:circle_limit=7'd122;
   12'd3854:circle_limit=7'd122;
   12'd3855:circle_limit=7'd122;
   12'd3856:circle_limit=7'd121;
   12'd3857:circle_limit=7'd121;
   12'd3858:circle_limit=7'd121;
   12'd3859:circle_limit=7'd120;
   12'd3860:circle_limit=7'd120;
   12'd3861:circle_limit=7'd120;
   12'd3862:circle_limit=7'd119;
   12'd3863:circle_limit=7'd119;
   12'd3864:circle_limit=7'd118;
   12'd3865:circle_limit=7'd118;
   12'd3866:circle_limit=7'd118;
   12'd3867:circle_limit=7'd117;
   12'd3868:circle_limit=7'd117;
   12'd3869:circle_limit=7'd116;
   12'd3870:circle_limit=7'd115;
   12'd3871:circle_limit=7'd115;
   12'd3872:circle_limit=7'd114;
   12'd3873:circle_limit=7'd114;
   12'd3874:circle_limit=7'd113;
   12'd3875:circle_limit=7'd112;
   12'd3876:circle_limit=7'd112;
   12'd3877:circle_limit=7'd111;
   12'd3878:circle_limit=7'd110;
   12'd3879:circle_limit=7'd109;
   12'd3880:circle_limit=7'd108;
   12'd3881:circle_limit=7'd107;
   12'd3882:circle_limit=7'd106;
   12'd3883:circle_limit=7'd105;
   12'd3884:circle_limit=7'd104;
   12'd3885:circle_limit=7'd103;
   12'd3886:circle_limit=7'd102;
   12'd3887:circle_limit=7'd101;
   12'd3888:circle_limit=7'd100;
   12'd3889:circle_limit=7'd98;
   12'd3890:circle_limit=7'd97;
   12'd3891:circle_limit=7'd95;
   12'd3892:circle_limit=7'd93;
   12'd3893:circle_limit=7'd92;
   12'd3894:circle_limit=7'd90;
   12'd3895:circle_limit=7'd87;
   12'd3896:circle_limit=7'd85;
   12'd3897:circle_limit=7'd82;
   12'd3898:circle_limit=7'd79;
   12'd3899:circle_limit=7'd74;
   12'd3900:circle_limit=7'd64;
   12'd3904:circle_limit=7'd125;
   12'd3905:circle_limit=7'd124;
   12'd3906:circle_limit=7'd124;
   12'd3907:circle_limit=7'd124;
   12'd3908:circle_limit=7'd124;
   12'd3909:circle_limit=7'd124;
   12'd3910:circle_limit=7'd124;
   12'd3911:circle_limit=7'd124;
   12'd3912:circle_limit=7'd124;
   12'd3913:circle_limit=7'd124;
   12'd3914:circle_limit=7'd124;
   12'd3915:circle_limit=7'd124;
   12'd3916:circle_limit=7'd123;
   12'd3917:circle_limit=7'd123;
   12'd3918:circle_limit=7'd123;
   12'd3919:circle_limit=7'd123;
   12'd3920:circle_limit=7'd122;
   12'd3921:circle_limit=7'd122;
   12'd3922:circle_limit=7'd122;
   12'd3923:circle_limit=7'd121;
   12'd3924:circle_limit=7'd121;
   12'd3925:circle_limit=7'd121;
   12'd3926:circle_limit=7'd120;
   12'd3927:circle_limit=7'd120;
   12'd3928:circle_limit=7'd120;
   12'd3929:circle_limit=7'd119;
   12'd3930:circle_limit=7'd119;
   12'd3931:circle_limit=7'd118;
   12'd3932:circle_limit=7'd118;
   12'd3933:circle_limit=7'd117;
   12'd3934:circle_limit=7'd117;
   12'd3935:circle_limit=7'd116;
   12'd3936:circle_limit=7'd115;
   12'd3937:circle_limit=7'd115;
   12'd3938:circle_limit=7'd114;
   12'd3939:circle_limit=7'd113;
   12'd3940:circle_limit=7'd113;
   12'd3941:circle_limit=7'd112;
   12'd3942:circle_limit=7'd111;
   12'd3943:circle_limit=7'd110;
   12'd3944:circle_limit=7'd110;
   12'd3945:circle_limit=7'd109;
   12'd3946:circle_limit=7'd108;
   12'd3947:circle_limit=7'd107;
   12'd3948:circle_limit=7'd106;
   12'd3949:circle_limit=7'd105;
   12'd3950:circle_limit=7'd104;
   12'd3951:circle_limit=7'd102;
   12'd3952:circle_limit=7'd101;
   12'd3953:circle_limit=7'd100;
   12'd3954:circle_limit=7'd98;
   12'd3955:circle_limit=7'd97;
   12'd3956:circle_limit=7'd95;
   12'd3957:circle_limit=7'd94;
   12'd3958:circle_limit=7'd92;
   12'd3959:circle_limit=7'd90;
   12'd3960:circle_limit=7'd88;
   12'd3961:circle_limit=7'd85;
   12'd3962:circle_limit=7'd82;
   12'd3963:circle_limit=7'd79;
   12'd3964:circle_limit=7'd75;
   12'd3965:circle_limit=7'd64;
   12'd3968:circle_limit=7'd126;
   12'd3969:circle_limit=7'd125;
   12'd3970:circle_limit=7'd125;
   12'd3971:circle_limit=7'd125;
   12'd3972:circle_limit=7'd125;
   12'd3973:circle_limit=7'd125;
   12'd3974:circle_limit=7'd125;
   12'd3975:circle_limit=7'd125;
   12'd3976:circle_limit=7'd125;
   12'd3977:circle_limit=7'd125;
   12'd3978:circle_limit=7'd125;
   12'd3979:circle_limit=7'd125;
   12'd3980:circle_limit=7'd124;
   12'd3981:circle_limit=7'd124;
   12'd3982:circle_limit=7'd124;
   12'd3983:circle_limit=7'd124;
   12'd3984:circle_limit=7'd123;
   12'd3985:circle_limit=7'd123;
   12'd3986:circle_limit=7'd123;
   12'd3987:circle_limit=7'd123;
   12'd3988:circle_limit=7'd122;
   12'd3989:circle_limit=7'd122;
   12'd3990:circle_limit=7'd121;
   12'd3991:circle_limit=7'd121;
   12'd3992:circle_limit=7'd121;
   12'd3993:circle_limit=7'd120;
   12'd3994:circle_limit=7'd120;
   12'd3995:circle_limit=7'd119;
   12'd3996:circle_limit=7'd119;
   12'd3997:circle_limit=7'd118;
   12'd3998:circle_limit=7'd118;
   12'd3999:circle_limit=7'd117;
   12'd4000:circle_limit=7'd117;
   12'd4001:circle_limit=7'd116;
   12'd4002:circle_limit=7'd115;
   12'd4003:circle_limit=7'd115;
   12'd4004:circle_limit=7'd114;
   12'd4005:circle_limit=7'd113;
   12'd4006:circle_limit=7'd112;
   12'd4007:circle_limit=7'd112;
   12'd4008:circle_limit=7'd111;
   12'd4009:circle_limit=7'd110;
   12'd4010:circle_limit=7'd109;
   12'd4011:circle_limit=7'd108;
   12'd4012:circle_limit=7'd107;
   12'd4013:circle_limit=7'd106;
   12'd4014:circle_limit=7'd105;
   12'd4015:circle_limit=7'd104;
   12'd4016:circle_limit=7'd103;
   12'd4017:circle_limit=7'd101;
   12'd4018:circle_limit=7'd100;
   12'd4019:circle_limit=7'd99;
   12'd4020:circle_limit=7'd97;
   12'd4021:circle_limit=7'd96;
   12'd4022:circle_limit=7'd94;
   12'd4023:circle_limit=7'd92;
   12'd4024:circle_limit=7'd90;
   12'd4025:circle_limit=7'd88;
   12'd4026:circle_limit=7'd85;
   12'd4027:circle_limit=7'd83;
   12'd4028:circle_limit=7'd79;
   12'd4029:circle_limit=7'd75;
   12'd4030:circle_limit=7'd64;
   12'd4032:circle_limit=7'd127;
   12'd4033:circle_limit=7'd126;
   12'd4034:circle_limit=7'd126;
   12'd4035:circle_limit=7'd126;
   12'd4036:circle_limit=7'd126;
   12'd4037:circle_limit=7'd126;
   12'd4038:circle_limit=7'd126;
   12'd4039:circle_limit=7'd126;
   12'd4040:circle_limit=7'd126;
   12'd4041:circle_limit=7'd126;
   12'd4042:circle_limit=7'd126;
   12'd4043:circle_limit=7'd126;
   12'd4044:circle_limit=7'd125;
   12'd4045:circle_limit=7'd125;
   12'd4046:circle_limit=7'd125;
   12'd4047:circle_limit=7'd125;
   12'd4048:circle_limit=7'd124;
   12'd4049:circle_limit=7'd124;
   12'd4050:circle_limit=7'd124;
   12'd4051:circle_limit=7'd124;
   12'd4052:circle_limit=7'd123;
   12'd4053:circle_limit=7'd123;
   12'd4054:circle_limit=7'd123;
   12'd4055:circle_limit=7'd122;
   12'd4056:circle_limit=7'd122;
   12'd4057:circle_limit=7'd121;
   12'd4058:circle_limit=7'd121;
   12'd4059:circle_limit=7'd120;
   12'd4060:circle_limit=7'd120;
   12'd4061:circle_limit=7'd119;
   12'd4062:circle_limit=7'd119;
   12'd4063:circle_limit=7'd118;
   12'd4064:circle_limit=7'd118;
   12'd4065:circle_limit=7'd117;
   12'd4066:circle_limit=7'd117;
   12'd4067:circle_limit=7'd116;
   12'd4068:circle_limit=7'd115;
   12'd4069:circle_limit=7'd114;
   12'd4070:circle_limit=7'd114;
   12'd4071:circle_limit=7'd113;
   12'd4072:circle_limit=7'd112;
   12'd4073:circle_limit=7'd111;
   12'd4074:circle_limit=7'd110;
   12'd4075:circle_limit=7'd110;
   12'd4076:circle_limit=7'd109;
   12'd4077:circle_limit=7'd108;
   12'd4078:circle_limit=7'd107;
   12'd4079:circle_limit=7'd105;
   12'd4080:circle_limit=7'd104;
   12'd4081:circle_limit=7'd103;
   12'd4082:circle_limit=7'd102;
   12'd4083:circle_limit=7'd100;
   12'd4084:circle_limit=7'd99;
   12'd4085:circle_limit=7'd98;
   12'd4086:circle_limit=7'd96;
   12'd4087:circle_limit=7'd94;
   12'd4088:circle_limit=7'd92;
   12'd4089:circle_limit=7'd90;
   12'd4090:circle_limit=7'd88;
   12'd4091:circle_limit=7'd86;
   12'd4092:circle_limit=7'd83;
   12'd4093:circle_limit=7'd79;
   12'd4094:circle_limit=7'd75;
   12'd4095:circle_limit=7'd64;
   default:circle_limit=0;
  endcase end
 endfunction
 function automatic rounded(input signed [12:0] sx,sy,x0,y0,w,h,r);
  reg [5:0] dx,dy;reg [6:0] boundary;begin
   dx=6'(sx<x0+r?x0+r-sx:sx>=x0+w-r?sx-(x0+w-r-1):0);
   dy=6'(sy<y0+r?y0+r-sy:sy>=y0+h-r?sy-(y0+h-r-1):0);
   boundary=circle_limit(6'(r),dx);
   rounded=sx>=x0 && sx<x0+w && sy>=y0 && sy<y0+h && boundary[6] && dy<=boundary[5:0];
  end
 endfunction
 function automatic integer white_key(input integer slot);
  begin case(slot)0:white_key=0;1:white_key=2;2:white_key=4;3:white_key=5;4:white_key=7;5:white_key=9;6:white_key=11;7:white_key=12;default:white_key=14;endcase end
 endfunction
 function automatic integer black_key(input integer slot);
  begin case(slot)0:black_key=1;1:black_key=3;2:black_key=6;3:black_key=8;4:black_key=10;default:black_key=13;endcase end
 endfunction
 function automatic integer black_gap(input integer slot);
  begin case(slot)0:black_gap=1;1:black_gap=2;2:black_gap=4;3:black_gap=5;4:black_gap=7;default:black_gap=8;endcase end
 endfunction
 function automatic integer fade7(input signed [11:0] numerator);
  reg signed [11:0] quotient;begin
   quotient=numerator/12'sd7;
   fade7={{20{quotient[11]}},quotient};
  end
 endfunction
 function automatic integer divide14(input signed [13:0] n,d);
  reg signed [13:0] q;begin q=n/d;divide14={{18{q[13]}},q};end
 endfunction
 function automatic integer remainder96(input signed [13:0] n);
  reg signed [13:0] q;begin q=n%14'sd96;remainder96={{18{q[13]}},q};end
 endfunction
 function automatic [35:0] guidance(input [35:0] original,input [4:0] key_index,
  input integer sx0,sy0,left,top,width,height,radius,
  input [31:0] touch,target,input enabled);
  begin
   guidance=original;
   if(enabled && rounded(sx0,sy0,left,top,width,height,radius))begin
    if(touch[key_index] && !target[key_index])begin
     guidance={12'd222,12'd139,12'd131};
    end
    if(target[key_index] &&
       !rounded(sx0,sy0,left+4,top+4,width-8,height-8,radius>4?radius-4:1))begin
     guidance={12'd255,12'd224,12'd159};
    end
    if(target[key_index] && sx0>=left+width/2-4 && sx0<left+width/2+4 &&
       sy0>=top+height-16 && sy0<top+height-9)guidance={12'd255,12'd221,12'd148};
   end
  end
 endfunction
 function automatic [7:0] key_abs(input signed [7:0] v);begin key_abs=v<0?-v:v;end endfunction

 function automatic [3:0] rim_light(input [3:0] r);begin case(r)
 4'd0:rim_light=4'd0;
 4'd1:rim_light=4'd0;
 4'd2:rim_light=4'd0;
 4'd3:rim_light=4'd0;
 4'd4:rim_light=4'd1;
 4'd5:rim_light=4'd1;
 4'd6:rim_light=4'd2;
 4'd7:rim_light=4'd3;
 4'd8:rim_light=4'd4;
 4'd9:rim_light=4'd6;
 4'd10:rim_light=4'd7;
 4'd11:rim_light=4'd9;
 4'd12:rim_light=4'd11;
 4'd13:rim_light=4'd13;
 default:rim_light=0;endcase end endfunction

 function automatic [10:0] unsigned_divide7(input [10:0] n);
 reg [22:0] p;begin p=23'(n)*23'd2341;unsigned_divide7=11'(p>>14);end endfunction

 function automatic [12:0] round_pane_prepared(input signed [12:0] sx,sy,x0,y0,w,h,right_start,right_last,bottom_start,bottom_last);
 reg [5:0] dx,dy;begin
 dx=6'((sx < 13'sd28) ? (13'sd28-sx) : (sx>=right_start ? sx-right_last : 0));
 dy=6'((sy < 13'sd28) ? (13'sd28-sy) : (sy>=bottom_start ? sy-bottom_last : 0));
 round_pane_prepared={sx>=x0 && sx<x0+w && sy>=y0 && sy<y0+h,dx,dy};
 end endfunction
 function automatic [12:0] round_geometry(input signed [12:0] sx,sy,x0,y0,w,h,r);
 reg [5:0] dx,dy;begin
 dx=6'(sx<x0+r?x0+r-sx:sx>=x0+w-r?sx-(x0+w-r-1):0);
 dy=6'(sy<y0+r?y0+r-sy:sy>=y0+h-r?sy-(y0+h-r-1):0);
 round_geometry={sx>=x0 && sx<x0+w && sy>=y0 && sy<y0+h,dx,dy};
 end endfunction
 function automatic round_finish(input [12:0] geometry,input [5:0] radius);
 reg [6:0] boundary;begin boundary=circle_limit(radius,geometry[11:6]);round_finish=geometry[12] && boundary[6] && geometry[5:0]<=boundary[5:0];end endfunction

 function automatic [7:0] min_key_edges(input [7:0] horizontal,top_edge,bottom_edge);
  reg [7:0] vertical;begin
   vertical=top_edge<bottom_edge?top_edge:bottom_edge;
   min_key_edges=horizontal<vertical?horizontal:vertical;
  end
 endfunction
 function automatic [11:0] div13_seed(input [5:0] hi);begin case(hi)
  6'd0:div13_seed=12'd0;
  6'd1:div13_seed=12'd38;
  6'd2:div13_seed=12'd76;
  6'd3:div13_seed=12'd117;
  6'd4:div13_seed=12'd155;
  6'd5:div13_seed=12'd196;
  6'd6:div13_seed=12'd234;
  6'd7:div13_seed=12'd275;
  6'd8:div13_seed=12'd313;
  6'd9:div13_seed=12'd354;
  6'd10:div13_seed=12'd392;
  6'd11:div13_seed=12'd433;
  6'd12:div13_seed=12'd471;
  6'd13:div13_seed=12'd512;
  6'd14:div13_seed=12'd550;
  6'd15:div13_seed=12'd588;
  6'd16:div13_seed=12'd629;
  6'd17:div13_seed=12'd667;
  6'd18:div13_seed=12'd708;
  6'd19:div13_seed=12'd746;
  6'd20:div13_seed=12'd787;
  6'd21:div13_seed=12'd825;
  6'd22:div13_seed=12'd866;
  6'd23:div13_seed=12'd904;
  6'd24:div13_seed=12'd945;
  6'd25:div13_seed=12'd983;
  6'd26:div13_seed=12'd1024;
  6'd27:div13_seed=12'd1062;
  6'd28:div13_seed=12'd1100;
  6'd29:div13_seed=12'd1141;
  6'd30:div13_seed=12'd1179;
  6'd31:div13_seed=12'd1220;
  6'd32:div13_seed=12'd1258;
  6'd33:div13_seed=12'd1299;
  6'd34:div13_seed=12'd1337;
  6'd35:div13_seed=12'd1378;
  6'd36:div13_seed=12'd1416;
  6'd37:div13_seed=12'd1457;
  6'd38:div13_seed=12'd1495;
  6'd39:div13_seed=12'd1536;
  6'd40:div13_seed=12'd1574;
  6'd41:div13_seed=12'd1612;
  6'd42:div13_seed=12'd1653;
  6'd43:div13_seed=12'd1691;
  6'd44:div13_seed=12'd1732;
  6'd45:div13_seed=12'd1770;
  6'd46:div13_seed=12'd1811;
  6'd47:div13_seed=12'd1849;
  6'd48:div13_seed=12'd1890;
  6'd49:div13_seed=12'd1928;
  6'd50:div13_seed=12'd1969;
  6'd51:div13_seed=12'd2007;
  6'd52:div13_seed=12'd2048;
  6'd53:div13_seed=12'd2086;
  6'd54:div13_seed=12'd2124;
  6'd55:div13_seed=12'd2165;
  6'd56:div13_seed=12'd2203;
  6'd57:div13_seed=12'd2244;
  6'd58:div13_seed=12'd2282;
  6'd59:div13_seed=12'd2323;
  6'd60:div13_seed=12'd2361;
  6'd61:div13_seed=12'd2402;
  6'd62:div13_seed=12'd2440;
  6'd63:div13_seed=12'd2481;
  default:div13_seed=0;endcase end endfunction
 function automatic [7:0] div13_finish(input [11:0] seed,input [4:0] lo);
  reg [5:0] residual;reg [1:0] correction;begin
   residual=6'(seed[3:0])+6'(lo);
   case(residual)
    6'd0:correction=2'd0;
    6'd1:correction=2'd0;
    6'd2:correction=2'd0;
    6'd3:correction=2'd0;
    6'd4:correction=2'd0;
    6'd5:correction=2'd0;
    6'd6:correction=2'd0;
    6'd7:correction=2'd0;
    6'd8:correction=2'd0;
    6'd9:correction=2'd0;
    6'd10:correction=2'd0;
    6'd11:correction=2'd0;
    6'd12:correction=2'd0;
    6'd13:correction=2'd1;
    6'd14:correction=2'd1;
    6'd15:correction=2'd1;
    6'd16:correction=2'd1;
    6'd17:correction=2'd1;
    6'd18:correction=2'd1;
    6'd19:correction=2'd1;
    6'd20:correction=2'd1;
    6'd21:correction=2'd1;
    6'd22:correction=2'd1;
    6'd23:correction=2'd1;
    6'd24:correction=2'd1;
    6'd25:correction=2'd1;
    6'd26:correction=2'd2;
    6'd27:correction=2'd2;
    6'd28:correction=2'd2;
    6'd29:correction=2'd2;
    6'd30:correction=2'd2;
    6'd31:correction=2'd2;
    6'd32:correction=2'd2;
    6'd33:correction=2'd2;
    6'd34:correction=2'd2;
    6'd35:correction=2'd2;
    6'd36:correction=2'd2;
    6'd37:correction=2'd2;
    6'd38:correction=2'd2;
    6'd39:correction=2'd3;
    6'd40:correction=2'd3;
    6'd41:correction=2'd3;
    6'd42:correction=2'd3;
    6'd43:correction=2'd3;
    default:correction=0;endcase
   div13_finish=seed[11:4]+8'(correction);
  end
 endfunction
 function automatic [10:0] div5_seed(input [4:0] hi);begin case(hi)
  5'd0:div5_seed=11'd0;
  5'd1:div5_seed=11'd50;
  5'd2:div5_seed=11'd100;
  5'd3:div5_seed=11'd153;
  5'd4:div5_seed=11'd203;
  5'd5:div5_seed=11'd256;
  5'd6:div5_seed=11'd306;
  5'd7:div5_seed=11'd356;
  5'd8:div5_seed=11'd409;
  5'd9:div5_seed=11'd459;
  5'd10:div5_seed=11'd512;
  5'd11:div5_seed=11'd562;
  5'd12:div5_seed=11'd612;
  5'd13:div5_seed=11'd665;
  5'd14:div5_seed=11'd715;
  5'd15:div5_seed=11'd768;
  5'd16:div5_seed=11'd818;
  5'd17:div5_seed=11'd868;
  5'd18:div5_seed=11'd921;
  5'd19:div5_seed=11'd971;
  5'd20:div5_seed=11'd1024;
  5'd21:div5_seed=11'd1074;
  5'd22:div5_seed=11'd1124;
  5'd23:div5_seed=11'd1177;
  5'd24:div5_seed=11'd1227;
  5'd25:div5_seed=11'd1280;
  5'd26:div5_seed=11'd1330;
  5'd27:div5_seed=11'd1380;
  5'd28:div5_seed=11'd1433;
  5'd29:div5_seed=11'd1483;
  5'd30:div5_seed=11'd1536;
  5'd31:div5_seed=11'd1586;
  default:div5_seed=0;endcase end endfunction
 function automatic [7:0] div5_finish(input [10:0] seed,input [4:0] lo);
  reg [5:0] residual;reg [2:0] correction;begin
   residual=6'(seed[2:0])+6'(lo);
   case(residual)
    6'd0:correction=3'd0;
    6'd1:correction=3'd0;
    6'd2:correction=3'd0;
    6'd3:correction=3'd0;
    6'd4:correction=3'd0;
    6'd5:correction=3'd1;
    6'd6:correction=3'd1;
    6'd7:correction=3'd1;
    6'd8:correction=3'd1;
    6'd9:correction=3'd1;
    6'd10:correction=3'd2;
    6'd11:correction=3'd2;
    6'd12:correction=3'd2;
    6'd13:correction=3'd2;
    6'd14:correction=3'd2;
    6'd15:correction=3'd3;
    6'd16:correction=3'd3;
    6'd17:correction=3'd3;
    6'd18:correction=3'd3;
    6'd19:correction=3'd3;
    6'd20:correction=3'd4;
    6'd21:correction=3'd4;
    6'd22:correction=3'd4;
    6'd23:correction=3'd4;
    6'd24:correction=3'd4;
    6'd25:correction=3'd5;
    6'd26:correction=3'd5;
    6'd27:correction=3'd5;
    6'd28:correction=3'd5;
    6'd29:correction=3'd5;
    6'd30:correction=3'd6;
    6'd31:correction=3'd6;
    6'd32:correction=3'd6;
    6'd33:correction=3'd6;
    6'd34:correction=3'd6;
    6'd35:correction=3'd7;
    default:correction=0;endcase
   div5_finish=seed[10:3]+8'(correction);
  end
 endfunction
 localparam PIPE_STAGES=40;
 typedef struct packed {
  logic signed [12:0] sx;
  logic signed [12:0] sy;
  logic signed [12:0] px;
  logic signed [12:0] py;
  logic signed [12:0] pw;
  logic signed [12:0] ph;
  logic signed [12:0] light;
  logic [7:0] key_top_edge,key_bottom_edge;
  logic [11:0] sx_div13_seed,ox_div13_seed;
  logic [10:0] sy_div5_seed,oy_div5_seed;
  logic signed [12:0] kx;
  logic signed [12:0] base;
  logic signed [12:0] edge_depth;
  logic signed [12:0] sx_part;
  logic signed [12:0] sy_part;
  logic signed [12:0] ox_part;
  logic signed [12:0] oy_part;
  logic signed [12:0] center_upper;
  logic signed [12:0] center_lower;
  logic signed [12:0] fraction;
  logic signed [12:0] key_x;
  logic signed [12:0] pane_x;
  logic signed [12:0] pane_y;
  logic signed [12:0] horizontal_edge;
  logic signed [12:0] pane_right;
  logic signed [12:0] pane_bottom;
  logic signed [12:0] glint_center;
  logic signed [12:0] glint_distance;
  logic [6:0] light_third;
  logic [6:0] rim_green;
  logic [10:0] nr_abs;
  logic [10:0] ng_abs;
  logic [10:0] nb_abs;
  logic [9:0] channel_sum;
  logic [5:0] black_mask;
  logic signed [11:0] rr;
  logic signed [11:0] gg;
  logic signed [11:0] bb;
  logic signed [11:0] nr;
  logic signed [11:0] ng;
  logic signed [11:0] nb;
  logic signed [11:0] nlight;
  logic signed [9:0] dx;
  logic signed [9:0] dy;
  logic signed [9:0] rim;
  logic signed [7:0] shine;
  logic signed [7:0] opposed;
  logic signed [7:0] shade;
  logic signed [7:0] glint;
  logic [1:0] key_kind;
  logic signed [8:0] absorption;
  logic signed [4:0] k;
  logic signed [6:0] idx;
  logic signed [2:0] board;
  logic [7:0] br;
  logic [7:0] bg;
  logic [7:0] bl;
  logic [7:0] fr;
  logic [7:0] fg;
  logic [7:0] fb;
  logic [2:0] amount;
  logic [12:0] pane_hit_geometry;
  logic [12:0] halo_outer_geometry;
  logic [12:0] halo_middle_geometry;
  logic [12:0] halo_inner_geometry;
  logic [12:0] pane_bevel_geometry;
  logic [31:0] voice_hits;
  logic [12:0] well_corner_0;
  logic [12:0] well_corner_1;
  logic [12:0] well_corner_2;
  logic [12:0] well_corner_3;
  logic [12:0] well_corner_4;
  logic [12:0] well_corner_5;
  logic [12:0] well_corner_6;
  logic [12:0] sound_corner_0;
  logic [12:0] sound_corner_1;
  logic [12:0] sound_corner_2;
  logic [12:0] sound_corner_3;
  logic [12:0] sound_corner_4;
  logic [6:0] well_hits;
  logic [4:0] sound_hits;
  logic header_divider;
  logic meter_hit;
  logic meter_low;
  logic meter_high;
  logic pane_hit;
  logic work_hit;
  logic pressed;
  logic status_live;
  logic guide_inner;
  logic guide_marker;
  logic halo_outer;
  logic halo_middle;
  logic halo_inner;
  logic pane_bevel;
  logic white_hit;
  logic upper_hit;
  logic nr_negative;
  logic ng_negative;
  logic nb_negative;
  logic [511:0] status_data;
  logic [95:0] key_trails;
  logic voice_pixel_shape,voice_pixel_active;
 // All five concentric pane borders have the same corner centers.
  logic signed [12:0] pane_right_start,pane_right_last,pane_bottom_start,pane_bottom_last;
 } pixel_state;
 // Branch frame_status: status, key trails and status_live change only at
 // blank_start, long before the next visible pixel; every stage reads them
 // directly. STAGE_1 onwards keep the original bits 50..81 drop.
 wire [511:0] frame_status_full=status_data;
 wire [511:0] frame_status_masked={status_data[511:82],32'd0,status_data[49:0]};
 pixel_state input_state;
 always @* begin input_state='0;input_state.status_data=status_data;input_state.status_live=status_live;input_state.key_trails=key_trails;end
 generate
 begin:STAGE_0 // pane selection
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_full;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=input_state;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys or x or y or drift_x or drift_y or sharp_rgb or frost_rgb) begin
   d=incoming;
  d.sx=32'(x);d.sy=32'(y);d.dx=32'($signed(drift_x));d.dy=32'($signed(drift_y));
if(MATERIAL_SAMPLE==0)begin
d.voice_hits[0]=rounded(d.sx,d.sy,1192,226,21,30,3);
d.voice_hits[1]=rounded(d.sx,d.sy,1219,226,21,30,3);
d.voice_hits[2]=rounded(d.sx,d.sy,1246,226,21,30,3);
d.voice_hits[3]=rounded(d.sx,d.sy,1273,226,21,30,3);
d.voice_hits[4]=rounded(d.sx,d.sy,1300,226,21,30,3);
d.voice_hits[5]=rounded(d.sx,d.sy,1327,226,21,30,3);
d.voice_hits[6]=rounded(d.sx,d.sy,1354,226,21,30,3);
d.voice_hits[7]=rounded(d.sx,d.sy,1381,226,21,30,3);
d.voice_hits[8]=rounded(d.sx,d.sy,1192,267,21,30,3);
d.voice_hits[9]=rounded(d.sx,d.sy,1219,267,21,30,3);
d.voice_hits[10]=rounded(d.sx,d.sy,1246,267,21,30,3);
d.voice_hits[11]=rounded(d.sx,d.sy,1273,267,21,30,3);
d.voice_hits[12]=rounded(d.sx,d.sy,1300,267,21,30,3);
d.voice_hits[13]=rounded(d.sx,d.sy,1327,267,21,30,3);
d.voice_hits[14]=rounded(d.sx,d.sy,1354,267,21,30,3);
d.voice_hits[15]=rounded(d.sx,d.sy,1381,267,21,30,3);
d.voice_hits[16]=rounded(d.sx,d.sy,1192,308,21,30,3);
d.voice_hits[17]=rounded(d.sx,d.sy,1219,308,21,30,3);
d.voice_hits[18]=rounded(d.sx,d.sy,1246,308,21,30,3);
d.voice_hits[19]=rounded(d.sx,d.sy,1273,308,21,30,3);
d.voice_hits[20]=rounded(d.sx,d.sy,1300,308,21,30,3);
d.voice_hits[21]=rounded(d.sx,d.sy,1327,308,21,30,3);
d.voice_hits[22]=rounded(d.sx,d.sy,1354,308,21,30,3);
d.voice_hits[23]=rounded(d.sx,d.sy,1381,308,21,30,3);
d.voice_hits[24]=rounded(d.sx,d.sy,1192,349,21,30,3);
d.voice_hits[25]=rounded(d.sx,d.sy,1219,349,21,30,3);
d.voice_hits[26]=rounded(d.sx,d.sy,1246,349,21,30,3);
d.voice_hits[27]=rounded(d.sx,d.sy,1273,349,21,30,3);
d.voice_hits[28]=rounded(d.sx,d.sy,1300,349,21,30,3);
d.voice_hits[29]=rounded(d.sx,d.sy,1327,349,21,30,3);
d.voice_hits[30]=rounded(d.sx,d.sy,1354,349,21,30,3);
d.voice_hits[31]=rounded(d.sx,d.sy,1381,349,21,30,3);
end
if(BACKGROUND_LATENCY==0)begin
  d.br=32'(sharp_rgb[23:16]);d.bg=32'(sharp_rgb[15:8]);d.bl=32'(sharp_rgb[7:0]);
  d.fr=32'(frost_rgb[23:16]);d.fg=32'(frost_rgb[15:8]);d.fb=32'(frost_rgb[7:0]);
  d.rr=d.br;d.gg=d.bg;d.bb=d.bl;
end
  d.px=0;d.py=0;d.pw=0;d.ph=0;d.light=0;d.idx=0;d.shade=0;d.base=0;d.board=0;d.pressed=0;d.kx=0;d.k=0;d.amount=0;
  d.edge_depth=0;d.rim=0;d.shine=0;d.opposed=0;d.absorption=0;d.glint=0;
  // Choose the nearest pane, including the narrow space occupied by its halo.
  if(d.sy<120)begin d.px=24;d.py=24;d.pw=1872;d.ph=92;end
  else if(d.sy<488)begin
   d.py=128;d.ph=352;
   if(d.sx<756)begin d.px=24;d.pw=724;end else if(d.sx<1496)begin d.px=764;d.pw=724;end else begin d.px=1504;d.pw=392;end
  end else if(d.sy<784)begin d.px=24;d.py=496;d.pw=1872;d.ph=248;end
  else begin d.py=792;d.ph=264;d.pw=928;d.px=d.sx<960?24:968;end
  if(MATERIAL_SAMPLE!=0)begin d.px=300;d.py=180;d.pw=1320;d.ph=720;end

  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_1 // pane local coordinates
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_0.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys or sharp_rgb or frost_rgb) begin
   d=incoming;
 // Both operands describe the same pixel captured at stage0. No change
 // in scene publication time or the independent audio voice bank.
 d.voice_pixel_shape=|incoming.voice_hits;
 d.voice_pixel_active=|(incoming.voice_hits & incoming_status[50+:32]);
 d.voice_hits=32'd0;
 d.status_data={incoming_status[511:82],32'd0,incoming_status[49:0]};
if(BACKGROUND_LATENCY==1)begin
  d.br=32'(sharp_rgb[23:16]);d.bg=32'(sharp_rgb[15:8]);d.bl=32'(sharp_rgb[7:0]);
  d.fr=32'(frost_rgb[23:16]);d.fg=32'(frost_rgb[15:8]);d.fb=32'(frost_rgb[7:0]);
  d.rr=d.br;d.gg=d.bg;d.bb=d.bl;
end
d.pane_x=d.sx-d.px;d.pane_y=d.sy-d.py;
d.pane_right_start=$signed({1'b0,d.pw})-13'sd28;
d.pane_right_last=$signed({1'b0,d.pw})-13'sd29;
d.pane_bottom_start=$signed({1'b0,d.ph})-13'sd28;
d.pane_bottom_last=$signed({1'b0,d.ph})-13'sd29;
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_2 // pane corner geometry
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_1.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys or sharp_rgb or frost_rgb) begin
   d=incoming;
if(BACKGROUND_LATENCY==2)begin
  d.br=32'(sharp_rgb[23:16]);d.bg=32'(sharp_rgb[15:8]);d.bl=32'(sharp_rgb[7:0]);
  d.fr=32'(frost_rgb[23:16]);d.fg=32'(frost_rgb[15:8]);d.fb=32'(frost_rgb[7:0]);
  d.rr=d.br;d.gg=d.bg;d.bb=d.bl;
end
d.pane_hit_geometry=round_pane_prepared(d.pane_x,d.pane_y,0,0,d.pw-(0),d.ph-(0),d.pane_right_start,d.pane_right_last,d.pane_bottom_start,d.pane_bottom_last);
d.halo_outer_geometry=round_pane_prepared(d.pane_x,d.pane_y,-7,-7,d.pw-(-14),d.ph-(-14),d.pane_right_start,d.pane_right_last,d.pane_bottom_start,d.pane_bottom_last);
d.halo_middle_geometry=round_pane_prepared(d.pane_x,d.pane_y,-4,-4,d.pw-(-8),d.ph-(-8),d.pane_right_start,d.pane_right_last,d.pane_bottom_start,d.pane_bottom_last);
d.halo_inner_geometry=round_pane_prepared(d.pane_x,d.pane_y,-2,-2,d.pw-(-4),d.ph-(-4),d.pane_right_start,d.pane_right_last,d.pane_bottom_start,d.pane_bottom_last);
d.pane_bevel_geometry=round_pane_prepared(d.pane_x,d.pane_y,1,1,d.pw-(2),d.ph-(2),d.pane_right_start,d.pane_right_last,d.pane_bottom_start,d.pane_bottom_last);
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_3 // pane masks
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_2.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys or sharp_rgb or frost_rgb) begin
   d=incoming;
if(BACKGROUND_LATENCY==3)begin
  d.br=32'(sharp_rgb[23:16]);d.bg=32'(sharp_rgb[15:8]);d.bl=32'(sharp_rgb[7:0]);
  d.fr=32'(frost_rgb[23:16]);d.fg=32'(frost_rgb[15:8]);d.fb=32'(frost_rgb[7:0]);
  d.rr=d.br;d.gg=d.bg;d.bb=d.bl;
end
d.pane_hit=round_finish(d.pane_hit_geometry,6'd28);
d.halo_outer=round_finish(d.halo_outer_geometry,6'd35);
d.halo_middle=round_finish(d.halo_middle_geometry,6'd32);
d.halo_inner=round_finish(d.halo_inner_geometry,6'd30);
d.pane_bevel=!round_finish(d.pane_bevel_geometry,6'd27);
d.pane_right=d.pw-1-d.pane_x;d.pane_bottom=d.ph-1-d.pane_y;
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_4 // pane color and edge distances
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_3.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys or sharp_rgb or frost_rgb) begin
   d=incoming;
if(BACKGROUND_LATENCY==4)begin
  d.br=32'(sharp_rgb[23:16]);d.bg=32'(sharp_rgb[15:8]);d.bl=32'(sharp_rgb[7:0]);
  d.fr=32'(frost_rgb[23:16]);d.fg=32'(frost_rgb[15:8]);d.fb=32'(frost_rgb[7:0]);
  d.rr=d.br;d.gg=d.bg;d.bb=d.bl;
end

 if(d.halo_outer)begin d.rr=d.rr+3;d.gg=d.gg+2;d.bb=d.bb+1;end
 if(d.halo_middle)begin d.rr=d.rr+5;d.gg=d.gg+4;d.bb=d.bb+2;end
 if(d.halo_inner)begin d.rr=d.rr+7;d.gg=d.gg+5;d.bb=d.bb+3;end
 if(d.pane_hit)begin
  d.edge_depth=d.pane_y;if(d.pane_bottom<d.edge_depth)d.edge_depth=d.pane_bottom;
  d.horizontal_edge=d.pane_x;if(d.pane_right<d.horizontal_edge)d.horizontal_edge=d.pane_right;
  d.rr=(d.fr*6+d.br+221)/8;d.gg=(d.fg*6+d.bg+225)/8;d.bb=(d.fb*6+d.bl+225)/8;
 end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_5 // nearest pane edge and material sum
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_4.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;

 if(d.pane_hit && d.horizontal_edge<d.edge_depth)d.edge_depth=d.horizontal_edge;
 d.channel_sum=d.rr+d.gg+d.bb;
 d.sx_div13_seed=div13_seed(d.pane_x[10:5]);d.ox_div13_seed=div13_seed(d.pane_right[10:5]);
 d.sy_div5_seed=div5_seed(d.pane_y[9:5]);d.oy_div5_seed=div5_seed(d.pane_bottom[9:5]);

 case(d.pw)
 1872:begin d.center_upper=1123;d.center_lower=748;end
 724:begin d.center_upper=434;d.center_lower=289;end
 392:begin d.center_upper=235;d.center_lower=156;end
 928:begin d.center_upper=556;d.center_lower=371;end
 1320:begin d.center_upper=792;d.center_lower=528;end
 default:begin d.center_upper=0;d.center_lower=0;end
 endcase
 
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_6 // material coordinate quotients
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_5.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;

 // These quotients are consumed only for d.pane_hit: distances are nonnegative.
 d.sx_part=13'(div13_finish(d.sx_div13_seed,d.pane_x[4:0]));d.sy_part=13'(div5_finish(d.sy_div5_seed,d.pane_y[4:0]));
 d.ox_part=13'(div13_finish(d.ox_div13_seed,d.pane_right[4:0]));d.oy_part=13'(div5_finish(d.oy_div5_seed,d.pane_bottom[4:0]));
 d.glint_center=d.sy<d.py+5?d.px+d.center_upper+d.dx:d.px+d.center_lower+d.dy;
 if(d.pane_hit)begin d.absorption=clamp($signed({1'b0,d.channel_sum/10'd3})-139,0,120);d.rim=clamp(13-d.edge_depth,0,13);end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_7 // reflection bounds
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_6.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;

 if(d.pane_hit)begin
  d.rr=d.rr-d.absorption;d.gg=d.gg-d.absorption;d.bb=d.bb-d.absorption;
  d.rim=32'(rim_light(4'(d.rim)));
  d.shine=clamp(42-d.sx_part-d.sy_part,0,42);d.opposed=clamp(34-d.ox_part-d.oy_part,0,34);
  d.glint_distance=d.sx-d.glint_center;
 end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_8 // reflection mix preparation
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_7.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(d.pane_hit)begin d.light=d.shine+d.opposed;d.glint=clamp(80-ab(d.glint_distance)/2,0,80);end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_9 // reflection component scalars
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_8.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(d.pane_hit)begin d.light_third=d.light[6:0]/7'd3;d.rim_green=(d.rim*5)/2;end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_10 // reflection mix
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_9.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(d.pane_hit)begin
 d.rr=d.rr+d.rim*3+d.light_third;d.gg=d.gg+d.rim_green+d.light_third;d.bb=d.bb+d.rim*2+d.light/4;
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_11 // bevel glint
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_10.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(d.pane_hit && (d.sy<d.py+5 || d.sy>=d.py+d.ph-5))begin
 d.rr=d.rr+d.glint/2;d.gg=d.gg+d.glint*3/8;d.bb=d.bb+d.glint/4;
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_12 // bevel edge
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_11.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(d.pane_hit)begin
 if(d.pane_bevel)begin d.rr=(d.rr+255)/2;d.gg=(d.gg+246)/2;d.bb=(d.bb+222)/2;end
 d.shade=clamp(52-(d.sy-d.py),0,52)/8;
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_13 // caption absorption
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_12.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
d.well_corner_0=round_geometry(d.sx,d.sy,42,186,688,274,18);
d.well_corner_1=round_geometry(d.sx,d.sy,782,186,688,274,18);
d.well_corner_2=round_geometry(d.sx,d.sy,1522,186,356,282,18);
d.well_corner_3=round_geometry(d.sx,d.sy,42,550,1836,176,18);
d.well_corner_4=round_geometry(d.sx,d.sy,42,830,892,208,18);
d.well_corner_5=round_geometry(d.sx,d.sy,986,830,892,208,18);
d.well_corner_6=round_geometry(d.sx,d.sy,24,752,1872,24,12);
d.sound_corner_0=round_geometry(d.sx,d.sy,54,68,7,16,3);
d.sound_corner_1=round_geometry(d.sx,d.sy,66,59,7,34,3);
d.sound_corner_2=round_geometry(d.sx,d.sy,78,51,7,50,3);
d.sound_corner_3=round_geometry(d.sx,d.sy,90,59,7,34,3);
d.sound_corner_4=round_geometry(d.sx,d.sy,102,68,7,16,3);
end
if(d.pane_hit)begin d.rr=d.rr-d.shade;d.gg=d.gg-d.shade;d.bb=d.bb-d.shade;end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_14 // plot well and header masks
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_13.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
d.well_hits[0]=round_finish(d.well_corner_0,6'd18);
d.well_hits[1]=round_finish(d.well_corner_1,6'd18);
d.well_hits[2]=round_finish(d.well_corner_2,6'd18);
d.well_hits[3]=round_finish(d.well_corner_3,6'd18);
d.well_hits[4]=round_finish(d.well_corner_4,6'd18);
d.well_hits[5]=round_finish(d.well_corner_5,6'd18);
d.well_hits[6]=round_finish(d.well_corner_6,6'd12);
d.sound_hits[0]=round_finish(d.sound_corner_0,6'd3);
d.sound_hits[1]=round_finish(d.sound_corner_1,6'd3);
d.sound_hits[2]=round_finish(d.sound_corner_2,6'd3);
d.sound_hits[3]=round_finish(d.sound_corner_3,6'd3);
d.sound_hits[4]=round_finish(d.sound_corner_4,6'd3);
d.header_divider=d.sy>=48 && d.sy<105 && (d.sx==430 || d.sx==710 || d.sx==950 || d.sx==1200 || d.sx==1510);
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_15 // plot wells and header
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_14.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if((|d.well_hits[5:0]) || (guide_mode && d.well_hits[6]))begin
 d.rr=d.fr*3/8+26;d.gg=d.fg*3/8+30;d.bb=d.fb*3/8+30;end
 if(d.header_divider)begin d.rr=109;d.gg=134;d.bb=150;end
 if(|d.sound_hits)begin d.rr=180;d.gg=244;d.bb=238;end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_16 // keyboard local coordinates
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_15.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin

 d.board=d.sx<960?0:1;d.base=d.sx<960?48:992;
 d.key_x=d.sx-d.base;d.work_hit=0;d.key_kind=0;d.kx=0;d.idx=0;
 
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_17 // white key slot
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_16.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin

 d.fraction=d.key_x[9:0]%10'd96;d.k=d.key_x[9:0]/10'd96;
 
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_18 // key shape masks
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_17.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin

 d.white_hit=d.key_x>=0 && d.key_x<864 && d.sy>=846 && d.sy<1006 && rounded(d.fraction,d.sy,1,846,93,160,6);
 d.upper_hit=rounded(d.key_x,d.sy,818,848,42,38,6);
 d.black_mask[0]=rounded(d.key_x,d.sy,70,846,52,102,5);
d.black_mask[1]=rounded(d.key_x,d.sy,166,846,52,102,5);
d.black_mask[2]=rounded(d.key_x,d.sy,358,846,52,102,5);
d.black_mask[3]=rounded(d.key_x,d.sy,454,846,52,102,5);
d.black_mask[4]=rounded(d.key_x,d.sy,646,846,52,102,5);
d.black_mask[5]=rounded(d.key_x,d.sy,742,846,52,102,5);

end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_19 // visible key selection
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_18.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
d.work_hit=d.white_hit || (|d.black_mask) || d.upper_hit;
 if(d.upper_hit)begin d.key_kind=2;d.kx=818;d.idx=d.board*16+15;end
 else if(|d.black_mask)begin d.key_kind=1;d.kx=(d.black_mask[0]?13'sd70:13'sd0) | (d.black_mask[1]?13'sd166:13'sd0) | (d.black_mask[2]?13'sd358:13'sd0) | (d.black_mask[3]?13'sd454:13'sd0) | (d.black_mask[4]?13'sd646:13'sd0) | (d.black_mask[5]?13'sd742:13'sd0);d.idx=d.board*16+((d.black_mask[0]?7'sd1:7'sd0) | (d.black_mask[1]?7'sd3:7'sd0) | (d.black_mask[2]?7'sd6:7'sd0) | (d.black_mask[3]?7'sd8:7'sd0) | (d.black_mask[4]?7'sd10:7'sd0) | (d.black_mask[5]?7'sd13:7'sd0));end
 else begin d.key_kind=0;d.kx=d.k*96+1;d.idx=d.board*16+white_key(d.k);end
 d.key_x=d.key_x-d.kx;
 
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_20 // physical key and release amount
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_19.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 d.pressed=shown_keys[d.idx];
 d.amount=d.pressed?7:!guide_mode && !auto_mode && d.status_live && incoming_status[0]?32'(incoming_trails[d.idx*3+:3]):0;
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_21 // key shade quotients
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_20.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 if(d.key_kind==0)begin d.sx_part=key_abs(8'(d.key_x-46))/8'd5;d.sy_part=8'(d.sy-846)/8'd20;end
 else if(d.key_kind==1)begin d.sx_part=key_abs(8'(d.key_x-26))/8'd3;d.sy_part=8'(d.sy-846)/8'd10;end
 else begin d.sx_part=8'(d.sy-848)>>1;d.sy_part=0;end
 d.light=d.key_x;if(92-d.key_x<d.light)d.light=92-d.key_x;
 // work_hit guarantees 846<=sy<=1005: both distances fit unsigned8.
 d.key_top_edge=8'(d.sy)-8'd78;d.key_bottom_edge=8'd237-8'(d.sy);
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_22 // key shade and vertical lip distance
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_21.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 d.shade=clamp(d.sx_part+d.sy_part,0,18);
 d.light={5'd0,min_key_edges(d.light[7:0],d.key_top_edge,d.key_bottom_edge)};
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_23 // key base color
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_22.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 if(d.key_kind==0)begin d.rr=251-d.shade;d.gg=249-d.shade;d.bb=245-d.shade;end
 else if(d.key_kind==1)begin d.rr=38-d.shade;d.gg=48-d.shade;d.bb=55-d.shade;end
 else begin d.rr=119-d.shade;d.gg=148-d.shade;d.bb=173-d.shade;end
 d.nlight=clamp(5-d.light,0,5)*d.amount;
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_24 // key tint products
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_23.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 if(d.key_kind==0)begin
 d.nr=(158-d.shade-d.rr)*d.amount;d.ng=((d.board==0?226:244)-d.shade-d.gg)*d.amount;d.nb=((d.board==0?249:212)-d.shade-d.bb)*d.amount;
 end else if(d.key_kind==1)begin
 d.nr=((d.board==0?115:105)-d.rr)*d.amount;d.ng=((d.board==0?182:200)-d.gg)*d.amount;d.nb=((d.board==0?227:189)-d.bb)*d.amount;
 end else begin
 d.nr=((d.board==0?161:157)-d.rr)*d.amount;d.ng=((d.board==0?222:236)-d.gg)*d.amount;d.nb=((d.board==0?248:220)-d.bb)*d.amount;
 end
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_25 // key tint magnitudes
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_24.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 d.nr_negative=d.nr<0;d.ng_negative=d.ng<0;d.nb_negative=d.nb<0;
 d.nr_abs=d.nr_negative?-d.nr:d.nr;d.ng_abs=d.ng_negative?-d.ng:d.ng;d.nb_abs=d.nb_negative?-d.nb:d.nb;
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_26 // key tint quotients
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_25.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 d.nr_abs=unsigned_divide7(d.nr_abs);d.ng_abs=unsigned_divide7(d.ng_abs);d.nb_abs=unsigned_divide7(d.nb_abs);d.light=unsigned_divide7({5'd0,6'(d.nlight)});
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_27 // key tint addition
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_26.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 d.rr=d.nr_negative?d.rr-d.nr_abs:d.rr+d.nr_abs;d.gg=d.ng_negative?d.gg-d.ng_abs:d.gg+d.ng_abs;d.bb=d.nb_negative?d.bb-d.nb_abs:d.bb+d.nb_abs;
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_28 // white key inner light
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_27.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit && d.key_kind==0)begin
 d.rr=d.rr+d.light*7;d.gg=d.gg+d.light*5;d.bb=d.bb+d.light*4;
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_29 // key bevel
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_28.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 if(d.key_kind==0 && (d.key_x==1 || d.sy==847))begin d.rr=239;d.gg=252;d.bb=255;end
 if(d.key_kind==1 && (d.key_x==1 || d.sy==847))begin d.rr=93;d.gg=112;d.bb=131;end
 if(d.key_kind==2 && !rounded(d.key_x,d.sy,1,849,40,36,5))begin d.rr=169;d.gg=208;d.bb=230;end
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_30 // key lower edge
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_29.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 if(d.key_kind==0 && d.sy>=1001)begin d.rr=(13'(d.rr)*13'sd7)>>>3;d.gg=(13'(d.gg)*13'sd7)>>>3;d.bb=(13'(d.bb)*13'sd7)>>>3;end
 if(d.key_kind==1 && d.sy>=942)begin d.rr=d.rr>>>1;d.gg=d.gg>>>1;d.bb=d.bb>>>1;end
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_31 // guidance key interior and marker
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_30.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit)begin
 if(d.key_kind==0)begin
  d.guide_inner=rounded(d.key_x,d.sy,4,850,85,152,2);
  d.guide_marker=d.key_x>=42 && d.key_x<50 && d.sy>=990 && d.sy<997;
 end else if(d.key_kind==1)begin
  d.guide_inner=rounded(d.key_x,d.sy,4,850,44,94,1);
  d.guide_marker=d.key_x>=22 && d.key_x<30 && d.sy>=932 && d.sy<939;
 end else begin
  d.guide_inner=rounded(d.key_x,d.sy,4,852,34,30,2);
  d.guide_marker=d.key_x>=17 && d.key_x<25 && d.sy>=870 && d.sy<877;
 end
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_32 // guidance key colors
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_31.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.work_hit && guide_mode && target_valid)begin
 if(physical[d.idx] && !targets[d.idx])begin d.rr=222;d.gg=139;d.bb=131;end
 if(targets[d.idx] && !d.guide_inner)begin d.rr=255;d.gg=224;d.bb=159;end
 if(targets[d.idx] && d.guide_marker)begin d.rr=255;d.gg=221;d.bb=148;end
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_33 // board 0 identity
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_32.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(rounded(d.sx,d.sy,52,811,12,12,6))begin d.rr=d.status_live && incoming_status[0]?128:117;d.gg=d.status_live && incoming_status[0]?244:132;d.bb=d.status_live && incoming_status[0]?224:143;end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_34 // board 1 identity
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_33.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(rounded(d.sx,d.sy,996,811,12,12,6))begin d.rr=d.status_live && incoming_status[0]?128:117;d.gg=d.status_live && incoming_status[0]?244:132;d.bb=d.status_live && incoming_status[0]?199:143;end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_35 // voice shape masks
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_34.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
































end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_36 // voice activity
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_35.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.voice_pixel_shape)begin
 d.rr=114;d.gg=133;d.bb=134;
 if(d.status_live && incoming_status[4] && d.voice_pixel_active)begin d.rr=176;d.gg=246;d.bb=220;end
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_37 // meter masks
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_36.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
d.meter_hit=(d.sx>=1424 && d.sx<1437 && d.sy>=414 && d.sy<422) || (d.sx>=1444 && d.sx<1457 && d.sy>=414 && d.sy<422) || (d.sx>=1424 && d.sx<1437 && d.sy>=402 && d.sy<410) || (d.sx>=1444 && d.sx<1457 && d.sy>=402 && d.sy<410) || (d.sx>=1424 && d.sx<1437 && d.sy>=390 && d.sy<398) || (d.sx>=1444 && d.sx<1457 && d.sy>=390 && d.sy<398) || (d.sx>=1424 && d.sx<1437 && d.sy>=378 && d.sy<386) || (d.sx>=1444 && d.sx<1457 && d.sy>=378 && d.sy<386) || (d.sx>=1424 && d.sx<1437 && d.sy>=366 && d.sy<374) || (d.sx>=1444 && d.sx<1457 && d.sy>=366 && d.sy<374) || (d.sx>=1424 && d.sx<1437 && d.sy>=354 && d.sy<362) || (d.sx>=1444 && d.sx<1457 && d.sy>=354 && d.sy<362) || (d.sx>=1424 && d.sx<1437 && d.sy>=342 && d.sy<350) || (d.sx>=1444 && d.sx<1457 && d.sy>=342 && d.sy<350) || (d.sx>=1424 && d.sx<1437 && d.sy>=330 && d.sy<338) || (d.sx>=1444 && d.sx<1457 && d.sy>=330 && d.sy<338) || (d.sx>=1424 && d.sx<1437 && d.sy>=318 && d.sy<326) || (d.sx>=1444 && d.sx<1457 && d.sy>=318 && d.sy<326) || (d.sx>=1424 && d.sx<1437 && d.sy>=306 && d.sy<314) || (d.sx>=1444 && d.sx<1457 && d.sy>=306 && d.sy<314) || (d.sx>=1424 && d.sx<1437 && d.sy>=294 && d.sy<302) || (d.sx>=1444 && d.sx<1457 && d.sy>=294 && d.sy<302) || (d.sx>=1424 && d.sx<1437 && d.sy>=282 && d.sy<290) || (d.sx>=1444 && d.sx<1457 && d.sy>=282 && d.sy<290) || (d.sx>=1424 && d.sx<1437 && d.sy>=270 && d.sy<278) || (d.sx>=1444 && d.sx<1457 && d.sy>=270 && d.sy<278) || (d.sx>=1424 && d.sx<1437 && d.sy>=258 && d.sy<266) || (d.sx>=1444 && d.sx<1457 && d.sy>=258 && d.sy<266) || (d.sx>=1424 && d.sx<1437 && d.sy>=246 && d.sy<254) || (d.sx>=1444 && d.sx<1457 && d.sy>=246 && d.sy<254) || (d.sx>=1424 && d.sx<1437 && d.sy>=234 && d.sy<242) || (d.sx>=1444 && d.sx<1457 && d.sy>=234 && d.sy<242);
d.meter_low=((d.sx>=1424 && d.sx<1437 && d.sy>=414 && d.sy<422) && incoming_status[434+:8]>8'd0) || ((d.sx>=1444 && d.sx<1457 && d.sy>=414 && d.sy<422) && incoming_status[442+:8]>8'd0) || ((d.sx>=1424 && d.sx<1437 && d.sy>=402 && d.sy<410) && incoming_status[434+:8]>8'd16) || ((d.sx>=1444 && d.sx<1457 && d.sy>=402 && d.sy<410) && incoming_status[442+:8]>8'd16) || ((d.sx>=1424 && d.sx<1437 && d.sy>=390 && d.sy<398) && incoming_status[434+:8]>8'd32) || ((d.sx>=1444 && d.sx<1457 && d.sy>=390 && d.sy<398) && incoming_status[442+:8]>8'd32) || ((d.sx>=1424 && d.sx<1437 && d.sy>=378 && d.sy<386) && incoming_status[434+:8]>8'd48) || ((d.sx>=1444 && d.sx<1457 && d.sy>=378 && d.sy<386) && incoming_status[442+:8]>8'd48) || ((d.sx>=1424 && d.sx<1437 && d.sy>=366 && d.sy<374) && incoming_status[434+:8]>8'd64) || ((d.sx>=1444 && d.sx<1457 && d.sy>=366 && d.sy<374) && incoming_status[442+:8]>8'd64) || ((d.sx>=1424 && d.sx<1437 && d.sy>=354 && d.sy<362) && incoming_status[434+:8]>8'd80) || ((d.sx>=1444 && d.sx<1457 && d.sy>=354 && d.sy<362) && incoming_status[442+:8]>8'd80) || ((d.sx>=1424 && d.sx<1437 && d.sy>=342 && d.sy<350) && incoming_status[434+:8]>8'd96) || ((d.sx>=1444 && d.sx<1457 && d.sy>=342 && d.sy<350) && incoming_status[442+:8]>8'd96) || ((d.sx>=1424 && d.sx<1437 && d.sy>=330 && d.sy<338) && incoming_status[434+:8]>8'd112) || ((d.sx>=1444 && d.sx<1457 && d.sy>=330 && d.sy<338) && incoming_status[442+:8]>8'd112) || ((d.sx>=1424 && d.sx<1437 && d.sy>=318 && d.sy<326) && incoming_status[434+:8]>8'd128) || ((d.sx>=1444 && d.sx<1457 && d.sy>=318 && d.sy<326) && incoming_status[442+:8]>8'd128) || ((d.sx>=1424 && d.sx<1437 && d.sy>=306 && d.sy<314) && incoming_status[434+:8]>8'd144) || ((d.sx>=1444 && d.sx<1457 && d.sy>=306 && d.sy<314) && incoming_status[442+:8]>8'd144) || ((d.sx>=1424 && d.sx<1437 && d.sy>=294 && d.sy<302) && incoming_status[434+:8]>8'd160) || ((d.sx>=1444 && d.sx<1457 && d.sy>=294 && d.sy<302) && incoming_status[442+:8]>8'd160) || ((d.sx>=1424 && d.sx<1437 && d.sy>=282 && d.sy<290) && incoming_status[434+:8]>8'd176) || ((d.sx>=1444 && d.sx<1457 && d.sy>=282 && d.sy<290) && incoming_status[442+:8]>8'd176);
d.meter_high=((d.sx>=1424 && d.sx<1437 && d.sy>=270 && d.sy<278) && incoming_status[434+:8]>8'd192) || ((d.sx>=1444 && d.sx<1457 && d.sy>=270 && d.sy<278) && incoming_status[442+:8]>8'd192) || ((d.sx>=1424 && d.sx<1437 && d.sy>=258 && d.sy<266) && incoming_status[434+:8]>8'd208) || ((d.sx>=1444 && d.sx<1457 && d.sy>=258 && d.sy<266) && incoming_status[442+:8]>8'd208) || ((d.sx>=1424 && d.sx<1437 && d.sy>=246 && d.sy<254) && incoming_status[434+:8]>8'd224) || ((d.sx>=1444 && d.sx<1457 && d.sy>=246 && d.sy<254) && incoming_status[442+:8]>8'd224) || ((d.sx>=1424 && d.sx<1437 && d.sy>=234 && d.sy<242) && incoming_status[434+:8]>8'd240) || ((d.sx>=1444 && d.sx<1457 && d.sy>=234 && d.sy<242) && incoming_status[442+:8]>8'd240);
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_38 // level meters
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_37.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
if(MATERIAL_SAMPLE==0)begin
if(d.meter_hit)begin d.rr=57;d.gg=75;d.bb=74;end
 if(d.status_live && incoming_status[6])begin
 if(d.meter_low)begin d.rr=163;d.gg=239;d.bb=207;end
 if(d.meter_high)begin d.rr=243;d.gg=229;d.bb=174;end
 end
end
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 begin:STAGE_39 // channel clipping
  pixel_state incoming,d,q_raw,q;
  always_comb begin q=q_raw;q.status_data=frame_status_masked;q.key_trails=key_trails;q.status_live=status_live;end
  wire [511:0] incoming_status=incoming.status_data;
  wire [95:0] incoming_trails=incoming.key_trails;
  assign incoming=STAGE_38.q;
 wire mode_valid=incoming.status_live && incoming.status_data[455] && incoming.status_data[456+:2]!=3;
 wire guide_mode=mode_valid && incoming.status_data[456+:2]==2;
 wire auto_mode=mode_valid && incoming.status_data[456+:2]==1;
 wire target_valid=mode_valid && (!guide_mode || incoming.status_data[0]) &&
  (incoming.status_data[490+:3]==2 || incoming.status_data[490+:3]==3);
 wire [31:0] targets=target_valid?incoming.status_data[458+:32]:32'd0;
 wire [31:0] physical=incoming.status_live && incoming.status_data[0]?incoming.status_data[18+:32]:32'd0;
 wire [31:0] shown_keys=auto_mode?targets:physical;

  integer i;
  always @(incoming or incoming_status or incoming_trails or mode_valid or guide_mode or auto_mode or target_valid or targets or physical or shown_keys) begin
   d=incoming;
d.rr=clamp(d.rr,0,255);d.gg=clamp(d.gg,0,255);d.bb=clamp(d.bb,0,255);
  end
  always @(posedge clk)begin
   q_raw<=d;
  end
 end
 endgenerate
 assign rgb={STAGE_39.q.rr[7:0],STAGE_39.q.gg[7:0],STAGE_39.q.bb[7:0]};
endmodule
// Exact 22s/29s motion. ROMs settle during vertical blank before active video.
module visual_light_motion(input wire clk,rst_n,frame_tick,
 output reg signed [9:0] drift_x,drift_y);
 reg [9:0] phase_x,phase_y;
 (* syn_romstyle="block_rom" *) reg [9:0] easing_x[0:1023],easing_y[0:1023];
 initial begin
  $readmemh("assets/display_drift_x.hex",easing_x);
  $readmemh("assets/display_drift_y.hex",easing_y);
 end
 always @(posedge clk)begin drift_x<=easing_x[phase_x];drift_y<=easing_y[phase_y];end
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin phase_x<=0;phase_y<=217;end
 else if(frame_tick)begin
  phase_x<=phase_x==659?10'd0:phase_x+1'b1;
  phase_y<=phase_y==869?10'd0:phase_y+1'b1;
 end
endmodule
`default_nettype wire
