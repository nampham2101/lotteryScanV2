// A copy of xskt.com.vn's miền Nam feed, https://xskt.com.vn/rss-feed/mien-nam-xsmn.rss,
// saved on 11 November 2026 and unchanged. Its five draw days run from
// 06/11/2026 (oldest) to 10/11/2026 (newest). Ticket #28's tests use it as
// "the feed above": it holds Bạc Liêu 10/11 (ĐB 267832, "7: 8078: 82") and
// Hồ Chí Minh 09/11 (ĐB 921440, Tám 43).
//
// It's kept as Dart, not as a file, so both the test app on the phone and the
// tests on the Mac can use the same copy. It must not import Flutter.

const savedFeed = r'''<?xml version="1.0" encoding="utf-8"?><rss version="2.0">
<channel>
<title>Kết quả xổ số Miền Nam</title>
<description>Kết quả xổ số Miền Nam - cập nhật hàng ngày</description>
<link>https://xskt.com.vn/xsmn</link>
<copyright>xskt.com.vn</copyright>
<generator>Xskt.com.vn:https://xskt.com.vn/rss</generator>
<pubDate>Wed, 11 Nov 2026 14:27:41 GMT</pubDate>
<lastBuildDate>Wed, 11 Nov 2026 14:27:41 GMT</lastBuildDate>
<item>
<title>KẾT QUẢ XỔ SỐ MIỀN NAM NGÀY 10/11 (Thứ Ba)</title>
<description>
[Bạc Liêu]     
ĐB: 267832
1: 06065
2: 37506
3: 68628 - 17545
4: 62894 - 33034 - 16748 - 10888 - 86497 - 16510 - 41069
5: 0183
6: 1701 - 5373 - 9768
7: 8078: 82
[Bến Tre]     
ĐB: 130694
1: 58758
2: 07993
3: 54069 - 09336
4: 75017 - 15500 - 35777 - 97561 - 98262 - 69634 - 77304
5: 5717
6: 8267 - 5330 - 9985
7: 8908: 99
[Vũng Tàu]     
ĐB: 283802
1: 59329
2: 56179
3: 45866 - 93323
4: 97537 - 79445 - 30625 - 47895 - 54913 - 98080 - 48572
5: 4851
6: 7835 - 2863 - 8429
7: 0958: 88</description>
<link>https://xskt.com.vn/xsmn/ngay-10-11-2026</link>
<pubDate>10/11/2026</pubDate>
</item>
<item>
<title>KẾT QUẢ XỔ SỐ MIỀN NAM NGÀY 09/11 (Thứ Hai)</title>
<description>
[Cà Mau]     
ĐB: 357120
1: 10026
2: 71465
3: 59651 - 85173
4: 82908 - 89032 - 56337 - 88848 - 58246 - 00706 - 86375
5: 6476
6: 9688 - 8292 - 7439
7: 6538: 77
[Đồng Tháp]     
ĐB: 539500
1: 72583
2: 03911
3: 91178 - 91995
4: 25896 - 05051 - 68462 - 39756 - 85650 - 80535 - 30708
5: 1311
6: 4588 - 5252 - 5843
7: 0218: 38
[Hồ Chí Minh]     
ĐB: 921440
1: 25520
2: 08652
3: 21731 - 40052
4: 48948 - 06412 - 45676 - 88736 - 42886 - 44309 - 87724
5: 2140
6: 2503 - 0433 - 7932
7: 0878: 43</description>
<link>https://xskt.com.vn/xsmn/ngay-9-11-2026</link>
<pubDate>10/11/2026</pubDate>
</item>
<item>
<title>KẾT QUẢ XỔ SỐ MIỀN NAM NGÀY 08/11 (Chủ Nhật)</title>
<description>
[Kiên Giang]     
ĐB: 296857
1: 39711
2: 03740
3: 03938 - 02582
4: 32844 - 28504 - 73152 - 35651 - 03367 - 32150 - 30769
5: 8952
6: 8480 - 6960 - 8749
7: 0488: 10
[Lâm Đồng]     
ĐB: 209181
1: 15454
2: 72524
3: 51978 - 45480
4: 73620 - 91006 - 14180 - 29240 - 14295 - 04043 - 50161
5: 7293
6: 6846 - 3130 - 6117
7: 1678: 34
[Tiền Giang]     
ĐB: 634295
1: 58662
2: 54435
3: 32628 - 04412
4: 83810 - 22503 - 18229 - 59485 - 47809 - 93062 - 52405
5: 7786
6: 3004 - 4463 - 7074
7: 8788: 45</description>
<link>https://xskt.com.vn/xsmn/ngay-8-11-2026</link>
<pubDate>10/11/2026</pubDate>
</item>
<item>
<title>KẾT QUẢ XỔ SỐ MIỀN NAM NGÀY 07/11 (Thứ Bảy)</title>
<description>
[Bình Phước]     
ĐB: 508805
1: 64229
2: 75545
3: 06275 - 35520
4: 37465 - 01695 - 41507 - 73219 - 97075 - 86244 - 00262
5: 0819
6: 0656 - 8893 - 7360
7: 4528: 15
[Hồ Chí Minh]     
ĐB: 274588
1: 66219
2: 57040
3: 41762 - 75058
4: 06509 - 93007 - 16758 - 66679 - 75842 - 01765 - 59607
5: 8011
6: 1387 - 2100 - 0266
7: 4208: 29
[Hậu Giang]     
ĐB: 830635
1: 63848
2: 01910
3: 73306 - 59274
4: 36171 - 38373 - 14145 - 84172 - 01468 - 86849 - 18088
5: 5930
6: 2419 - 8989 - 0888
7: 5888: 12
[Long An]     
ĐB: 471941
1: 20048
2: 92892
3: 18007 - 26706
4: 35611 - 57269 - 26262 - 31803 - 99408 - 27204 - 55861
5: 3176
6: 8644 - 5424 - 3047
7: 0438: 34</description>
<link>https://xskt.com.vn/xsmn/ngay-7-11-2026</link>
<pubDate>10/11/2026</pubDate>
</item>
<item>
<title>KẾT QUẢ XỔ SỐ MIỀN NAM NGÀY 06/11 (Thứ Sáu)</title>
<description>
[Bình Dương]     
ĐB: 122483
1: 18867
2: 82056
3: 63708 - 45963
4: 29904 - 49110 - 55073 - 21084 - 10100 - 14920 - 86826
5: 2930
6: 3859 - 7005 - 7988
7: 4168: 88
[Trà Vinh]     
ĐB: 836482
1: 13108
2: 66773
3: 01040 - 50402
4: 30388 - 29602 - 34164 - 41017 - 67947 - 04784 - 90330
5: 1435
6: 0979 - 1818 - 8072
7: 9278: 65
[Vĩnh Long]     
ĐB: 598254
1: 62299
2: 39045
3: 38704 - 25442
4: 04023 - 55225 - 00062 - 90636 - 93265 - 05243 - 70141
5: 8439
6: 0877 - 6838 - 0983
7: 0158: 17</description>
<link>https://xskt.com.vn/xsmn/ngay-6-11-2026</link>
<pubDate>10/11/2026</pubDate>
</item>
</channel>
</rss>''';
