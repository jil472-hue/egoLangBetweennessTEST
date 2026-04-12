# REAME


# egoLangBetweenness

Compute ego language betweenness from personal network data.

This package provides tools to quantify how often an ego serves as a
bridge between alters from different language communities within an ego
network.

------------------------------------------------------------------------

## Overview

In bilingualism research, language use is often embedded in social
networks. Individuals interact with people who may differ in their
language preferences, and these patterns shape opportunities for
code-switching and language control.

**Ego language betweenness** captures the extent to which an individual
(ego) connects otherwise separated language communities in their
personal network.

Conceptually, this measure answers:

> *How often does the ego lie on shortest paths between alters from
> different language communities?*

-   A value of **0** indicates that the ego does not bridge across
    language communities 

-   Higher values indicate that the ego is a central connector across
    communities 

**[Try the interactive example](https://jil472-hue.github.io/egoLangBetweennessTEST/ego_betweenness_interactive_example.html)** — play with the network to see how the score is computed step by step.

This measure complements existing indices such as language entropy by
focusing on **network structure rather than usage proportions**.

------------------------------------------------------------------------

## Installation

To use the package, you need to install the development version from
GitHub on R:

``` r
# Install devtools package if you never installed this before
if(!"devtools" %in% rownames(installed.packages())) install.packages("devtools")

# Install the development version from github
devtools::install_github("jil472-hue/egoLangBetweennessTEST")
```

    ── R CMD build ─────────────────────────────────────────────────────────────────

    * checking for file 'C:\Users\Zoey\AppData\Local\Temp\RtmpYHqUKc\remotesdd804fb91d8\jil472-hue-egoLangBetweennessTEST-53f2154/DESCRIPTION' ... OK
    * preparing 'egoLangBetweenness':
    * checking DESCRIPTION meta-information ... OK
    * checking for LF line-endings in source and make files and shell scripts
    * checking for empty or unneeded directories
    * building 'egoLangBetweenness_0.0.0.9000.tar.gz'

## Usage

This package works on ego-network data. It assumes that the input data
have been preprocessed, such that each alter is already assigned to a
language category (e.g., `languageUsedCategory`). Users should
refer to **[preprocessing
pipeline](pns_preprocessing/pns_preprocessing.html##2.1-language-categorization)**
for workflow (You may need to download it for the full view)

The input typically consists of:

-   `ego` → defines **who the participants are**
-   `alter` → defines **who is in each ego’s network + their
    attributes**
-   `edges` → defines **how alters are connected to each other**

To compute ego language betweenness, the dataset must minimally include
the variables listed in the table below:

<table>
<colgroup>
<col style="width: 21%" />
<col style="width: 30%" />
<col style="width: 21%" />
<col style="width: 26%" />
</colgroup>
<thead>
<tr>
<th>Dataset</th>
<th>Variable</th>
<th>Description</th>
<th>Role in analysis</th>
</tr>
</thead>
<tbody>
<tr>
<td><strong>ego</strong></td>
<td><code>networkCanvasEgoUUID</code></td>
<td>Unique identifier for each ego</td>
<td>Used to define and iterate over ego networks</td>
</tr>
<tr>
<td><strong>ego</strong></td>
<td><code>participant</code></td>
<td>Unique participant identifier</td>
<td>Unique identifier for each participant, used to integrate network
science questionnaire data with additional questionnaires and
experimental data.</td>
</tr>
<tr>
<td><strong>alter</strong></td>
<td><code>networkCanvasEgoUUID</code></td>
<td>Ego ID for each alter</td>
<td>Links alters to their ego</td>
</tr>
<tr>
<td><strong>alter</strong></td>
<td><code>networkCanvasUUID</code></td>
<td>Unique identifier for each alter</td>
<td>Node identifier in the network</td>
</tr>
<tr>
<td><strong>alter</strong></td>
<td><code>languageUsedCategory</code></td>
<td>Language community (e.g., English, Spanish, Bilingual)</td>
<td>Defines community membership for betweenness</td>
</tr>
<tr>
<td><strong>edges</strong></td>
<td><code>networkCanvasEgoUUID</code></td>
<td>Ego ID for each edge</td>
<td>Ensures edges are within the same network</td>
</tr>
<tr>
<td><strong>edges</strong></td>
<td><code>networkCanvasSourceUUID</code></td>
<td>Source alter ID</td>
<td>Defines edge (node–node connection)</td>
</tr>
<tr>
<td><strong>edges</strong></td>
<td><code>networkCanvasTargetUUID</code></td>
<td>Target alter ID</td>
<td>Defines edge (node–node connection)</td>
</tr>
</tbody>
</table>

### Example data

Below is an example using demo data included in the package. Suppose we
have ten ego networks, where alters are categorized as `"English"`,
`"Spanish"`, or `"Bilingual"`.

#### Load ego-level data

``` r
ego <- read.csv("demo_data/ego_dataset.csv")
print(ego)
```

       networkCanvasEgoUUID participant
    1                ego_01      low_01
    2                ego_02     high_02
    3                ego_03   medium_03
    4                ego_04   medium_04
    5                ego_05   medium_05
    6                ego_06   medium_06
    7                ego_07   medium_07
    8                ego_08   medium_08
    9                ego_09   medium_09
    10               ego_10   medium_10

#### Load alter-level data

``` r
alter <- read.csv("demo_data/alter_dataset.csv")
print(alter)
```

       networkCanvasEgoUUID networkCanvasUUID languageUsedCategory
    1                ego_01                a1              English
    2                ego_01                a2              English
    3                ego_01                a3              English
    4                ego_01                a4              English
    5                ego_01                a5              English
    6                ego_02                b1              English
    7                ego_02                b2              Spanish
    8                ego_02                b3              Spanish
    9                ego_02                b4            Bilingual
    10               ego_02                b5              English
    11               ego_03                c1              English
    12               ego_03                c2              Spanish
    13               ego_03                c3              English
    14               ego_03                c5            Bilingual
    15               ego_03                c4            Bilingual
    16               ego_04                d1              English
    17               ego_04                d2              English
    18               ego_04                d3              Spanish
    19               ego_04                d4              Spanish
    20               ego_04                d5            Bilingual
    21               ego_05                e1              English
    22               ego_05                e2              English
    23               ego_05                e3              Spanish
    24               ego_05                e4              Spanish
    25               ego_05                e5            Bilingual
    26               ego_06                f1              English
    27               ego_06                f2              Spanish
    28               ego_06                f3              English
    29               ego_06                f4            Bilingual
    30               ego_06                f5            Bilingual
    31               ego_07                g1              English
    32               ego_07                g2              English
    33               ego_07                g3              Spanish
    34               ego_07                g4              Spanish
    35               ego_07                g5            Bilingual
    36               ego_08                h1              English
    37               ego_08                h2              Spanish
    38               ego_08                h3            Bilingual
    39               ego_08                h4              English
    40               ego_08                h5              Spanish
    41               ego_09                i1              English
    42               ego_09                i2              English
    43               ego_09                i3            Bilingual
    44               ego_09                i4              Spanish
    45               ego_09                i5            Bilingual
    46               ego_10                j1              Spanish
    47               ego_10                j2              Spanish
    48               ego_10                j3            Bilingual
    49               ego_10                j4              English
    50               ego_10                j5            Bilingual

#### Load edge-level data

``` r
edges <- read.csv("demo_data/edges_dataset.csv")
print(edges)
```

       networkCanvasEgoUUID networkCanvasSourceUUID networkCanvasTargetUUID
    1                ego_01                      a1                      a3
    2                ego_01                      a2                      a4
    3                ego_01                      a1                      a4
    4                ego_01                      a2                      a3
    5                ego_03                      c1                      c2
    6                ego_04                      d1                      d3
    7                ego_04                      d2                      d4
    8                ego_05                      e1                      e3
    9                ego_05                      e2                      e3
    10               ego_06                      f1                      f5
    11               ego_06                      f2                      f5
    12               ego_07                      g1                      g5
    13               ego_07                      g3                      g4
    14               ego_08                      h1                      h2
    15               ego_08                      h3                      h4
    16               ego_09                      i1                      i3
    17               ego_09                      i2                      i4
    18               ego_10                      j1                      j4

## Step 1: Load required packages

First, load the necessary packages. This includes the core network
analysis package <u>**igraph**</u> and the **egoLangBetweenness**
package.

``` r
library(igraph)
library(egoLangBetweenness)
```

## Step 2: Compute ego language betweenness

We compute ego language betweenness for each ego network using the
function  
`ego_language_betweenness_dataset()`.

This function takes three dataframes as input:

-   `ego_df`: ego-level data (participants)

-   `alter_df`: alter-level data (network members + language category)

-   `edge_df`: edge-level data (connections between alters)

``` r
betweenness_df <- ego_language_betweenness_dataset(
  ego_df = ego,
  alter_df = alter,
  edge_df = edges
)
```

This step automatically:

-   Constructs an ego network for each participant

-   Identifies language communities based on `languageUsedCategory`

-   Computes shortest paths between alters

-   Calculates how often the ego lies on shortest paths **between alters
    from different language communities**

## Step 3: Inspect the output

The resulting dataframe contains one row per ego:

``` r
print(betweenness_df)
```

       ego_id language_betweenness n_valid_pairs participant
    1  ego_01                  0.0             0      low_01
    2  ego_02                  8.0             8     high_02
    3  ego_03                  7.0             8   medium_03
    4  ego_04                  6.0             8   medium_04
    5  ego_05                  6.0             8   medium_05
    6  ego_06                  5.5             8   medium_06
    7  ego_07                  7.0             8   medium_07
    8  ego_08                  6.0             8   medium_08
    9  ego_09                  6.0             8   medium_09
    10 ego_10                  7.0             8   medium_10

The output dataframe contains one row per ego, along with variables
capturing both network identifiers and key quantities involved in the
computation of ego language betweenness:

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead>
<tr>
<th>Column name</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>networkCanvasEgoUUID</code></td>
<td>Unique identifier for each ego network</td>
</tr>
<tr>
<td><code>participant</code></td>
<td>Participant ID (can be used to merge with other datasets)</td>
</tr>
<tr>
<td><code>ego_language_betweenness</code></td>
<td>The computed betweenness value for the ego</td>
</tr>
<tr>
<td><code>n_valid_pairs</code></td>
<td>Total number of alter pairs from different language communities
considered in the computation</td>
</tr>
</tbody>
</table>
