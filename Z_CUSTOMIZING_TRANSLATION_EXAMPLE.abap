*&---------------------------------------------------------------------*
*& Report: Z_CUSTOMIZING_TRANSLATION_EXAMPLE
*& Purpose: Practical example of translating SAP customizing entries
*& Usage: Demonstrate real-world translation scenarios
*&---------------------------------------------------------------------*
REPORT z_customizing_translation_example.

" This program demonstrates how to handle translations for common
" SAP customizing entries that are encountered in real projects

TABLES: t005t, tcurt, t151t, tvkot, tvgrt.

" Selection screen for customizing translation examples
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS: p_lang TYPE spras DEFAULT sy-langu OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-002.
PARAMETERS: p_ctry AS CHECKBOX DEFAULT 'X',
            p_curr AS CHECKBOX DEFAULT 'X', 
            p_cgrp AS CHECKBOX DEFAULT 'X',
            p_sorg AS CHECKBOX DEFAULT 'X',
            p_cust AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

" Text elements
" text-001: 'Target Language'
" text-002: 'Customizing Areas'

" Data declarations
DATA: BEGIN OF gs_stats,
        total_entries TYPE i,
        translated_entries TYPE i,
        missing_translations TYPE i,
        completion_percentage TYPE p DECIMALS 2,
      END OF gs_stats.

START-OF-SELECTION.

  WRITE: / 'SAP Customizing Translation Examples',
         / 'Target Language:', p_lang,
         / '=' && cl_abap_char_utilities=>horizontal_tab.

  " Example 1: Country/Region translations
  IF p_ctry = 'X'.
    PERFORM translate_countries.
  ENDIF.

  " Example 2: Currency translations  
  IF p_curr = 'X'.
    PERFORM translate_currencies.
  ENDIF.

  " Example 3: Customer group translations
  IF p_cgrp = 'X'.
    PERFORM translate_customer_groups.
  ENDIF.

  " Example 4: Sales organization translations
  IF p_sorg = 'X'.
    PERFORM translate_sales_orgs.
  ENDIF.

  " Example 5: Custom table translations
  IF p_cust = 'X'.
    PERFORM custom_table_translation.
  ENDIF.

  " Summary statistics
  PERFORM display_summary_statistics.

*&---------------------------------------------------------------------*
*& Form: TRANSLATE_COUNTRIES
*& Purpose: Show how to handle country/region translations
*&---------------------------------------------------------------------*
FORM translate_countries.

  WRITE: / 'EXAMPLE 1: Country/Region Translations',
         / '----------------------------------------'.

  " Get all countries with their translations
  SELECT land1, landx 
    FROM t005t
    WHERE spras = @p_lang
    INTO TABLE @DATA(lt_countries)
    UP TO 10 ROWS.

  IF sy-subrc = 0.
    WRITE: / 'Countries in language', p_lang, ':'.
    LOOP AT lt_countries INTO DATA(ls_country).
      WRITE: / '  ', ls_country-land1, '-', ls_country-landx.
    ENDLOOP.
  ELSE.
    " Fallback to English
    SELECT land1, landx 
      FROM t005t
      WHERE spras = 'E'
      INTO TABLE lt_countries
      UP TO 10 ROWS.
    
    WRITE: / 'No translations found in', p_lang, '- showing English fallback:'.
    LOOP AT lt_countries INTO ls_country.
      WRITE: / '  ', ls_country-land1, '-', ls_country-landx.
    ENDLOOP.
  ENDIF.

  " Check translation completeness
  SELECT COUNT(*) FROM t005t WHERE spras = 'E' INTO @DATA(lv_total_countries).
  SELECT COUNT(*) FROM t005t WHERE spras = @p_lang INTO @DATA(lv_translated_countries).
  
  DATA(lv_country_completion) = COND p( 
    WHEN lv_total_countries > 0 
    THEN ( lv_translated_countries / lv_total_countries ) * 100 
    ELSE 0 
  ).
  
  WRITE: / 'Translation Completeness:', lv_country_completion, '% (',
           lv_translated_countries, 'of', lv_total_countries, 'translated)'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form: TRANSLATE_CURRENCIES  
*& Purpose: Show how to handle currency translations
*&---------------------------------------------------------------------*
FORM translate_currencies.

  SKIP 1.
  WRITE: / 'EXAMPLE 2: Currency Translations',
         / '-------------------------------'.

  " Get currency translations with fallback logic
  DATA: lt_currencies TYPE TABLE OF tcurt.

  " Try target language first
  SELECT * FROM tcurt 
    WHERE spras = @p_lang
    INTO TABLE @lt_currencies
    UP TO 10 ROWS.

  IF lines( lt_currencies ) = 0.
    " Fallback to English
    SELECT * FROM tcurt 
      WHERE spras = 'E'
      INTO TABLE lt_currencies
      UP TO 10 ROWS.
    WRITE: / 'Currency translations (English fallback):'.
  ELSE.
    WRITE: / 'Currency translations in', p_lang, ':'.
  ENDIF.

  LOOP AT lt_currencies INTO DATA(ls_currency).
    WRITE: / '  ', ls_currency-waers, '-', ls_currency-ltext.
  ENDLOOP.

  " Show how to programmatically create missing translations
  WRITE: / 'Creating missing currency translation example:'.
  
  " Check if EUR translation exists in target language
  SELECT SINGLE waers FROM tcurt 
    INTO @DATA(lv_eur_check)
    WHERE spras = @p_lang AND waers = 'EUR'.
    
  IF sy-subrc <> 0.
    WRITE: / '  EUR translation missing in', p_lang.
    
    " Get English version as template
    SELECT SINGLE ltext FROM tcurt 
      INTO @DATA(lv_eur_english)
      WHERE spras = 'E' AND waers = 'EUR'.
      
    IF sy-subrc = 0.
      WRITE: / '  English template:', lv_eur_english.
      
      " In real scenario, you would:
      " 1. Translate the text (manually or via service)
      " 2. Insert the new translation
      " INSERT tcurt FROM VALUE #( spras = p_lang waers = 'EUR' ltext = translated_text ).
      WRITE: / '  >> Would create translation entry here'.
    ENDIF.
  ELSE.
    WRITE: / '  EUR translation exists in', p_lang.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form: TRANSLATE_CUSTOMER_GROUPS
*& Purpose: Show customer group translation handling
*&---------------------------------------------------------------------*
FORM translate_customer_groups.

  SKIP 1.
  WRITE: / 'EXAMPLE 3: Customer Group Translations',
         / '-------------------------------------'.

  " Customer groups are in table T151T
  SELECT kdgrp, ktext 
    FROM t151t
    WHERE spras = @p_lang
    INTO TABLE @DATA(lt_customer_groups)
    UP TO 5 ROWS.

  IF lines( lt_customer_groups ) > 0.
    WRITE: / 'Customer groups in', p_lang, ':'.
    LOOP AT lt_customer_groups INTO DATA(ls_cgroup).
      WRITE: / '  ', ls_cgroup-kdgrp, '-', ls_cgroup-ktext.
    ENDLOOP.
  ELSE.
    WRITE: / 'No customer group translations found in', p_lang.
    
    " Show structure for manual translation
    SELECT kdgrp, ktext 
      FROM t151t
      WHERE spras = 'E'
      INTO TABLE lt_customer_groups
      UP TO 3 ROWS.
      
    WRITE: / 'Source texts (English) for translation:'.
    LOOP AT lt_customer_groups INTO ls_cgroup.
      WRITE: / '  ', ls_cgroup-kdgrp, ':', ls_cgroup-ktext.
      WRITE: / '    >> Translation needed for language', p_lang.
    ENDLOOP.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form: TRANSLATE_SALES_ORGS
*& Purpose: Show sales organization translation handling
*&---------------------------------------------------------------------*
FORM translate_sales_orgs.

  SKIP 1.
  WRITE: / 'EXAMPLE 4: Sales Organization Translations',
         / '----------------------------------------'.

  " Sales organizations are in table TVKOT
  SELECT vkorg, vtext 
    FROM tvkot
    WHERE spras = @p_lang
    INTO TABLE @DATA(lt_sales_orgs)
    UP TO 5 ROWS.

  IF lines( lt_sales_orgs ) > 0.
    WRITE: / 'Sales organizations in', p_lang, ':'.
    LOOP AT lt_sales_orgs INTO DATA(ls_sorg).
      WRITE: / '  ', ls_sorg-vkorg, '-', ls_sorg-vtext.
    ENDLOOP.
  ELSE.
    WRITE: / 'No sales organization translations in', p_lang.
    
    " Show how to identify untranslated entries
    SELECT DISTINCT v1~vkorg
      FROM tvko AS v1
      LEFT JOIN tvkot AS v2 ON v1~vkorg = v2~vkorg AND v2~spras = @p_lang
      WHERE v2~vkorg IS NULL
      INTO TABLE @DATA(lt_missing_sales_orgs)
      UP TO 3 ROWS.
      
    IF lines( lt_missing_sales_orgs ) > 0.
      WRITE: / 'Sales organizations needing translation:'.
      LOOP AT lt_missing_sales_orgs INTO DATA(lv_missing_sorg).
        
        " Get English description as reference
        SELECT SINGLE vtext FROM tvkot 
          INTO @DATA(lv_english_desc)
          WHERE vkorg = @lv_missing_sorg AND spras = 'E'.
          
        WRITE: / '  ', lv_missing_sorg, '(EN:', lv_english_desc, ')'.
      ENDLOOP.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form: CUSTOM_TABLE_TRANSLATION
*& Purpose: Show how to implement translation for custom tables
*&---------------------------------------------------------------------*
FORM custom_table_translation.

  SKIP 1.
  WRITE: / 'EXAMPLE 5: Custom Table Translation Pattern',
         / '----------------------------------------'.

  WRITE: / 'Pattern for custom table with translations:'.
  WRITE: / ''.
  WRITE: / '1. Master Table (ZCUSTOM_MASTER):'.
  WRITE: / '   - ID (Key)'.
  WRITE: / '   - OTHER_FIELDS...'.
  WRITE: / ''.
  WRITE: / '2. Text Table (ZCUSTOM_MASTER_T):'.
  WRITE: / '   - CLIENT (Key)'.
  WRITE: / '   - ID (Key, Foreign Key to Master)'.
  WRITE: / '   - SPRAS (Key, Language)'.
  WRITE: / '   - DESCRIPTION (Text field)'.
  WRITE: / ''.
  
  " Simulate reading from custom text table
  WRITE: / 'Example: Reading custom table with translation:'.
  WRITE: / ''.
  WRITE: / 'ABAP Code Pattern:'.
  WRITE: / 'SELECT m~id, t~description'.
  WRITE: / '  FROM zcustom_master AS m'.
  WRITE: / '  LEFT JOIN zcustom_master_t AS t'.
  WRITE: / '    ON m~id = t~id'.
  WRITE: / '   AND t~spras = @p_lang'.
  WRITE: / '  WHERE m~active = ''X'''.
  WRITE: / '  INTO TABLE @lt_result.'.
  WRITE: / ''.
  
  " Show fallback pattern
  WRITE: / 'Fallback Implementation:'.
  WRITE: / 'IF lines( lt_result ) = 0 OR'.
  WRITE: / '   line_exists( lt_result[ description = '''' ] ).'.
  WRITE: / '  " Repeat query with fallback language (''E'')'.
  WRITE: / 'ENDIF.'.

  " Demonstrate translation maintenance pattern
  WRITE: / ''.
  WRITE: / 'Translation Maintenance via SM30:'.
  WRITE: / '- Create maintenance view for text table'.
  WRITE: / '- Include language field in key'.
  WRITE: / '- Set up proper authorization groups'.
  WRITE: / '- Enable change documents for audit trail'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form: DISPLAY_SUMMARY_STATISTICS
*& Purpose: Show overall translation status summary
*&---------------------------------------------------------------------*
FORM display_summary_statistics.

  SKIP 2.
  WRITE: / 'TRANSLATION STATUS SUMMARY',
         / '========================='.

  " Calculate overall statistics across all demonstrated areas
  DATA: lv_total_tables TYPE i VALUE 5,
        lv_tables_with_translations TYPE i.

  " Check each table for translations in target language
  SELECT COUNT(*) FROM t005t WHERE spras = @p_lang INTO @DATA(lv_countries).
  SELECT COUNT(*) FROM tcurt WHERE spras = @p_lang INTO @DATA(lv_currencies).
  SELECT COUNT(*) FROM t151t WHERE spras = @p_lang INTO @DATA(lv_cgroups).
  SELECT COUNT(*) FROM tvkot WHERE spras = @p_lang INTO @DATA(lv_sorgs).

  " Count tables with translations
  IF lv_countries > 0. lv_tables_with_translations = lv_tables_with_translations + 1. ENDIF.
  IF lv_currencies > 0. lv_tables_with_translations = lv_tables_with_translations + 1. ENDIF.
  IF lv_cgroups > 0. lv_tables_with_translations = lv_tables_with_translations + 1. ENDIF.
  IF lv_sorgs > 0. lv_tables_with_translations = lv_tables_with_translations + 1. ENDIF.

  WRITE: / 'Language:', p_lang.
  WRITE: / 'Tables checked:', lv_total_tables.
  WRITE: / 'Tables with translations:', lv_tables_with_translations.
  
  DATA(lv_overall_completion) = ( lv_tables_with_translations / lv_total_tables ) * 100.
  WRITE: / 'Overall completion:', lv_overall_completion, '%'.

  WRITE: / ''.
  WRITE: / 'Detailed Statistics:'.
  WRITE: / '  Countries (T005T):', lv_countries, 'entries'.
  WRITE: / '  Currencies (TCURT):', lv_currencies, 'entries'.
  WRITE: / '  Customer Groups (T151T):', lv_cgroups, 'entries'.
  WRITE: / '  Sales Organizations (TVKOT):', lv_sorgs, 'entries'.

  " Recommendations
  SKIP 1.
  WRITE: / 'RECOMMENDATIONS:'.
  WRITE: / '================'.
  
  IF lv_overall_completion < 50.
    WRITE: / '- Consider implementing translation workflow'.
    WRITE: / '- Set up regular translation maintenance cycles'.
    WRITE: / '- Train key users on translation tools (SE63)'.
  ELSEIF lv_overall_completion < 90.
    WRITE: / '- Good translation coverage, focus on missing areas'.
    WRITE: / '- Implement quality checks for existing translations'.
    WRITE: / '- Consider automated translation for low-priority items'.
  ELSE.
    WRITE: / '- Excellent translation coverage!'.
    WRITE: / '- Maintain regular review cycles'.
    WRITE: / '- Monitor for new customizing entries'.
  ENDIF.

  WRITE: / ''.
  WRITE: / 'Next Steps:'.
  WRITE: / '- Use SE63 (Translation Workbench) for systematic translation'.
  WRITE: / '- Implement custom translation framework for Z-tables'.
  WRITE: / '- Set up transport procedures for translation objects'.
  WRITE: / '- Create documentation for translation maintenance'.

ENDFORM.