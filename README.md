# Adjusting the ASEC tax filing status variable (FILESTAT)

## Detailed Report

This [report](https://github.com/jo-fleck/ASEC_FILESTAT_adjustment/blob/master/Report_ASEC_FILESTAT_adjustment.pdf) documents erroneous variation in the ASEC tax filing status variable (FILESTAT) in 2004 and 2005. It also shows how to adjust the variable so that it aligns with other years.

## Summary of the Erroneous Variation

The CPS ASEC variable FILESTAT reports the federal income tax filing status. Its values are imputed by the Census Bureau's Tax Model and provide six different tax filing status categories:

| Code   | Label           
| :----: |-------------------------------------|
| 1      | Joint, both less than 65            |
| 2      | Joint, one less than 65 and one 65+ |
| 3      | Joint, both 65+                     |
| 4      | Head of household                   |
| 5      | Single                              |
| 6      | Nonfiler                            |

As the panels below illustrate, the share of nonfilers appears to be much larger in 2004 and 2005. The reverse applies to the share of joint filers below 65 while the shares of head of household and single filers seem comparable across years.

![FILESTAT Comparison](FILESTAT_2003to2006.png)

## Materials in this Repository

* The adjustment algorithm in the file `FILESTAT_adj_2004.jl` corrects the discrepancies for the year 2004. It can easily be applied to other years and reproduced in other languages.

* `Report_ASEC_FILESTAT_adjustment.pdf` contains a brief technical report on the FILESTAT discrepancies. This report presents more details on the FILESTAT discrepancies, the adjustment algorithm and the adjusted values of FILESTAT.

* `FILESTAT_adj.jl` generates the figures and tables shown in the technical report.

* `FILESTAT_post_2005.jl` investigates additional FILESTAT inconsistencies after 2005.

* The corresponding [IPUMS User Forum Thread](https://forum.ipums.org/t/filestat-comparability/3544)
