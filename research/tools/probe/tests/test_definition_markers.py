"""Offline checks of the row-count regex markers in the five Phase 5 candidate definitions.

Each snippet imitates the markup shape a real page is likely to use (URL shapes confirmed in
search where noted). The point is distinct-row counting: an id that appears in an href, a second
href, a data attribute and embedded JSON must count once, and plausible markup must not count 0.
No network.
"""
import time
from pathlib import Path

import pytest

from probe.definition import load_definition
from probe.extract import extract

DEFS = Path(__file__).resolve().parents[1] / "definitions"


def rows(name: str, body: str) -> int:
    defn = load_definition(DEFS / f"{name}.yaml")
    n, _, err = extract(body.encode("utf-8"), defn.extract)
    assert err is None
    return n


# --------------------------------------------------------------- 1. mortgage rates

MORTGAGE = """
<table><tbody>
<tr><td>2 year fixed</td><td class="rate">4.69%</td><td>Overall cost 6.9% APRC</td><td>&pound;999</td><td>60% LTV</td></tr>
<tr><td>2 year fixed</td><td class="rate">4.79 %</td><td>7.0% APRC</td><td>&pound;0</td><td>75% LTV</td></tr>
<tr><td>5 year fixed</td><td class="rate">4.69%</td><td>6.4% APRC</td><td>&pound;999</td><td>60% LTV</td></tr>
<tr><td>5 year fixed</td><td class="rate">4.89&nbsp;%</td><td>6.5% APRC</td><td>&pound;999</td><td>85% LTV</td></tr>
<tr><td>10 year fixed</td><td class="rate"><span>5.04</span><span class="pct">%</span></td><td>6.1% APRC</td></tr>
<tr><td>10 year fixed</td><td class="rate">14.69%</td></tr>
</tbody></table>
<div class="mobile-card">4.79%</div>
<script>window.rates={"initialRate":"4.89%","svr":"6.99%"}</script>
<p>Our standard variable rate is 6.99%. Bank of England base rate 4.00%.</p>
"""


def test_mortgage_distinct_rates():
    # distinct 2-dp rates: 4.69 4.79 4.89 5.04 14.69 6.99 4.00 -> 7 (1-dp APRC / LTV ignored)
    assert rows("uk-mortgage-lender-rates", MORTGAGE) == 7


def test_mortgage_split_span_and_dup_forms():
    body = '<b>4.69</b><sup>%</sup> ... 4.69 % ... 4.69&nbsp;% ... <span class="x">4.69</span>%'
    assert rows("uk-mortgage-lender-rates", body) == 1
    assert rows("uk-mortgage-lender-rates", "rate 3.5% and version 1.4.69% and 104.69%") == 0


# --------------------------------------------------------------- 2. GCC grocery

GROCERY = """
<div class="product-card"><a href="/en-ae/deerma-smart-robotic-vacuum/p/2662930/"><img src="https://cdn.example/2662930.jpg"></a>
<a href="/en-ae/deerma-smart-robotic-vacuum/p/2662930/" class="title">Deerma</a></div>
<div class="product-card"><a href="/mafuae/en/rice-semolina/crf-bio-rice-drink-1l/p/592447">Rice drink</a>
<a href="/mafuae/en/rice-semolina/crf-bio-rice-drink-1l/p/592447?offer=1">Add</a></div>
<div class="product-card"><a href="/mafuae/en/x/p/5924470">Other</a></div>
<div class="product-card"><a href="/mafuae/en/y/p/1881649009311">Cream</a></div>
<script id="__NEXT_DATA__" type="application/json">{"props":{"products":[
{"url":"/en-ae/deerma-smart-robotic-vacuum/p/2662930/","sku":"2662930"},
{"url":"/mafuae/en/rice-semolina/crf-bio-rice-drink-1l/p/592447","id":"592447"},
{"url":"/mafuae/en/y/p/1881649009311"}]}}</script>
<a href="/p/12">not a product id</a>
"""


def test_grocery_distinct_ids():
    assert rows("gcc-grocery-lulu-carrefour", GROCERY) == 4


# --------------------------------------------------------------- 3. Currys + Screwfix

RETAIL = """
<div data-qaid="product-tile"><a href="/p/makita-dhp484z-18v-li-ion-lxt-brushless-cordless-combi-drill-bare/3738v"><img></a>
<a href="/p/makita-dhp484z-18v-li-ion-lxt-brushless-cordless-combi-drill-bare/3738v" data-qaid="product_description">Makita</a>
<a href="/p/makita-dhp484z-18v-li-ion-lxt-brushless-cordless-combi-drill-bare/3738v#reviews">12 reviews</a></div>
<div data-qaid="product-tile"><a href='/p/dewalt-dcz298d2t-sfgb-18v-2-x-2-0ah-li-ion-xr-cordless-combi-drill-impact-driver-twin-pack/920hp'>DeWalt</a></div>
<div data-qaid="product-tile"><a href="/p/x-drill/3738">Prefix-code product</a></div>
<div data-qaid="product-tile"><a href="/p/x-drill/37381">Longer-code product, same slug</a></div>
<div class="product" data-pid="10284802"><a href="https://www.currys.co.uk/products/acer-aspire-go-15-15.6-laptop-amd-ryzen-7-1-tb-ssd-silver-10284802.html">ACER</a>
<a href="/products/acer-aspire-go-15-15.6-laptop-amd-ryzen-7-1-tb-ssd-silver-10284802.html?bvstate=pg:2">Reviews</a></div>
<div class="product" data-pid="10262983"><a href="/products/samsung-qe55q60d-55-smart-4k-qled-tv-10262983.html">Samsung</a></div>
<script type="application/ld+json">{"itemListElement":[{"url":"https://www.screwfix.com/p/makita-dhp484z-18v-li-ion-lxt-brushless-cordless-combi-drill-bare/3738v"},
{"url":"https://www.currys.co.uk/products/samsung-qe55q60d-55-smart-4k-qled-tv-10262983.html"}]}</script>
"""


def test_retail_distinct_ids_incl_dotted_currys_slug():
    # Screwfix 3738v, 920hp, x-drill/3738, x-drill/37381 ; Currys 10284802 (slug has "15.6"), 10262983
    assert rows("uk-retail-currys-screwfix", RETAIL) == 6


# --------------------------------------------------------------- 4. tenders

ETIMAD_JSON = ('{"data":[' + ",".join(
    '{"tenderId":%d,"tenderIdString":"Zx%dG%%2BqF0%%3D","referenceNumber":"2310390064%02d","agencyName":"MoH",'
    '"lastTender":{"tenderId":%d}}' % (412300 + i, i, i, 412300 + i) for i in range(24)) + '],"totalCount":9000}')

TENDERS_HTML = """
<div class="tender-card"><a href="/Tender/DetailsForVisitor?STenderId=Zx8G%2BqF0kL2b0g%3D%3D">Supply of PCs</a>
<a href="/Tender/DetailsForVisitor?STenderId=Zx8G%2BqF0kL2b0g%3D%3D" class="btn">Details</a></div>
<div class="tender-card"><a href="/Tender/DetailsForVisitor?STenderId=Ab9H%2Bxyz123%3D">Road works</a></div>
<table><tr><td>TS0000006507E</td><td><a href="/public/tenders/view/TS0000006507E">view</a></td></tr>
<tr><td>TS0000006508E</td></tr></table>
<a href="https://pa.epads.gov.pk/procurement/goods/110295/sbd">Notice</a>
<a href="https://pa.epads.gov.pk/procurement/goods/110295">Notice</a>
<a href="https://pa.epads.gov.pk/procurement/works/1102951">Other</a>
"""


def test_tenders_json_counts_each_tender_once():
    assert rows("tenders-pk-epads-sa-etimad", ETIMAD_JSON) == 24


def test_tenders_html_distinct_ids():
    # 2 STenderId + 2 TS..E + 2 EPADS
    assert rows("tenders-pk-epads-sa-etimad", TENDERS_HTML) == 6


# --------------------------------------------------------------- 5. jobs

JOBS = """
<li data-js-job="" data-job-id="5460283"><h2><a href="/en/uae/jobs/senior-accountant-5460283/">Senior Accountant</a></h2>
<a href="/en/uae/jobs/senior-accountant-5460283/?apply=1">Apply</a></li>
<li data-js-job="" data-job-id="5460299"><a href="/en/uae/jobs/%D9%85%D8%AD%D8%A7%D8%B3%D8%A8-5460299/">Arabic title</a></li>
<li data-js-job=""><a href="/en/uae/jobs/sales-jobs-5460300/">Sales</a></li>
<a href="/en/uae/jobs/accountant-jobs-in-dubai/?page=2">Next</a>
<script type="application/ld+json">{"url":"https://www.bayt.com/en/uae/jobs/senior-accountant-5460283/"}</script>
<div class="ng-box srp-tuple"><a href="https://www.naukrigulf.com/python-developer-jobs-in-abu-dhabi-uae-in-tasc-outsourcing-8-to-9-years-n-cd-23461-jid-190526000214">Python</a>
<a href="/python-developer-jobs-in-abu-dhabi-uae-in-tasc-outsourcing-8-to-9-years-n-cd-23461-jid-190526000214?src=srp">x</a></div>
<div class="job"><a href="https://www.rozee.pk/ansaar-management-company-pvt-limited-accountant-lahore-jobs-1799200">Accountant</a></div>
<div class="job"><a href="//www.rozee.pk/accountant-lahore-jobs-1820014">Accountant</a></div>
<a href="https://www.rozee.pk/category/-jobs-in-lahore">Lahore</a>
"""


def test_jobs_distinct_ids():
    # Bayt 5460283, 5460299 (percent-encoded slug), 5460300 ; Naukrigulf 1 ; Rozee 2
    assert rows("jobs-bayt-naukrigulf-rozee", JOBS) == 6


# --------------------------------------------------------------- speed

@pytest.mark.parametrize("name,body", [
    ("uk-mortgage-lender-rates", MORTGAGE), ("gcc-grocery-lulu-carrefour", GROCERY),
    ("uk-retail-currys-screwfix", RETAIL), ("tenders-pk-epads-sa-etimad", TENDERS_HTML),
    ("jobs-bayt-naukrigulf-rozee", JOBS)])
def test_markers_fast_enough_on_large_page(name, body):
    big = ("<div>" + "x" * 900 + " 12.3 /p/ jobs- </div>\n") * 1000 + body * 20  # ~1 MB
    t = time.perf_counter()
    rows(name, big)
    assert time.perf_counter() - t < 15


def test_distinct_counting_is_fast_on_large_pages():
    # ~1.5 MB listing page with 20k links over 5k distinct ids; the old dedupe lookahead took seconds.
    body = "".join(f'<a href="/p/{i % 5000 + 10000}">x</a><div>{"y" * 60}</div>' for i in range(20000))
    t = time.perf_counter()
    n = rows("gcc-grocery-lulu-carrefour", body)
    assert n == 5000
    assert time.perf_counter() - t < 1.0
