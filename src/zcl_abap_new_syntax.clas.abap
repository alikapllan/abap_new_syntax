CLASS zcl_abap_new_syntax DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_test_type_checking .
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA number TYPE int2 .

    METHODS inline_declarations .           " DATA, Field-Symbols, LOOP REFERENCE INTO DATA
    METHODS constructor_expressions .      " VALUE, CORRESPONDING, BASE, NEW, REF, FOR, REDUCE, FILTER
    METHODS conditional_expressions .      " SWITCH, xsdbool, COND
    METHODS internal_table_expressions .
    METHODS loop_at_group_by .
    METHODS type_checking .                " IS INSTANCE OF, CASE TYPE OF
    METHODS conversions .                  " ALPHA Conversion, Date Format, Time Format, TIMESTAMP, Case of Text, Number Format
    METHODS enhanced_sql_syntax .          " SELECT with FIELD, SELECT with Subquery, VALUE within INSERT
    " JOINS, UNION, Aggregation Functions, Arithmetic Operations, SQL String Expressions
    " and CASE - COALESCE
ENDCLASS.



CLASS zcl_abap_new_syntax IMPLEMENTATION.


  METHOD conditional_expressions.
    SELECT FROM scarr
      FIELDS *
      INTO TABLE @DATA(lt_scarr).

    LOOP AT lt_scarr INTO DATA(ls_scarr).

      " SWITCH to determine carrier status
      DATA(lv_status) = SWITCH #( ls_scarr-carrid
                                  WHEN 'LH' THEN 'Major   '
                                  WHEN 'AA' THEN 'Global  '
                                  ELSE           'Regional' ).

      " xsdbool to check if the carrier uses EUR as currency
      DATA(lv_is_currency_euro) = xsdbool( ls_scarr-currcode = 'EUR' ).

      " COND to assign a description based on destinations
      DATA(lv_description_cur) = COND #( WHEN lv_is_currency_euro = abap_true THEN 'Euro currency '
                                         WHEN ls_scarr-currcode   = 'USD'     THEN 'Dolar currency'
                                         ELSE                                      'Other currency' ).

      CONCATENATE ls_scarr-carrname lv_status 'uses' lv_description_cur
                  INTO DATA(lv_summary) SEPARATED BY space.

*      out->write( lv_summary ).
    ENDLOOP.
  ENDMETHOD.


  METHOD constructor_expressions.

* VALUE, CORRESPONDING, BASE, NEW, REF, FOR, REDUCE, FILTER
*--------------------------------------------------------------------*
*& VALUE
    TYPES: BEGIN OF lty_student,
             id   TYPE int2,
             name TYPE char40,
           END OF lty_student,
           ltt_student TYPE STANDARD TABLE OF lty_student
                                          WITH EMPTY KEY.

    " VALUE with structure
    DATA(ls_student) = VALUE lty_student( id = 1 name = 'Jack' ).


    " VALUE with iTab - 1
    DATA(lt_student) = VALUE ltt_student( ( id = 2 name = 'Ashley' ) ).

    " VALUE with iTab - 2
    DATA: lt_student2 TYPE ltt_student.
    lt_student2 = VALUE #( ( id = 3 name = 'Richard' )
                           ( id = 4 name = 'Anna'    ) ).

    " INSERT VALUE - no extra data definition needed
    INSERT VALUE #( id = 5 name = 'Ben' ) INTO TABLE lt_student2.
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*& CORRESPONDING & BASE
    TYPES: BEGIN OF lty_scarr,
             carrname TYPE scarr-carrname,
             currcode TYPE scarr-currcode,
             carrid   TYPE scarr-carrid, " id not in the beginning
             " no url field
           END OF lty_scarr,
           ltt_scarr TYPE STANDARD TABLE OF lty_scarr WITH EMPTY KEY.

    DATA: lt_scarr_no_url TYPE ltt_scarr.

    SELECT FROM scarr
        FIELDS *
        INTO CORRESPONDING FIELDS OF TABLE @lt_scarr_no_url
        UP TO 5 ROWS.

    " CORRESPONDING -> Field names and its types should be identical
    DATA(lt_scarr_no_url2) = CORRESPONDING ltt_scarr( lt_scarr_no_url ).

    SELECT FROM scarr
        FIELDS *
        WHERE carrid = 'UA'
        INTO TABLE @DATA(lt_scarr) UP TO 1 ROWS.

    " BASE keeps the former values inside
    lt_scarr_no_url2 = CORRESPONDING #( BASE ( lt_scarr_no_url2 ) lt_scarr ).
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*& NEW & REF
    DATA: oref  TYPE REF TO zcl_abap_new_syntax,
          dref1 LIKE REF TO oref,
          dref2 TYPE REF TO int2.

    oref  = NEW #(  ).     " creates object from class
    " DATA(oref) = NEW zcl_test_02_constructor_expr(  ). " with inline dec.

    dref1 = REF #( oref ). " holds object reference
    dref2 = NEW #(  ).     " holds data reference
    dref2->* = dref1->*->number.
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*& FOR
    TYPES: BEGIN OF lty_carrier,
             carrid   TYPE scarr-carrid,
             carrname TYPE scarr-carrname,
           END OF lty_carrier,
           ltt_carrier TYPE STANDARD TABLE OF lty_carrier WITH EMPTY KEY.

    SELECT FROM scarr
      FIELDS *
      INTO TABLE @lt_scarr.

    " FOR
    DATA(lt_carriers) = VALUE ltt_carrier( FOR carr IN lt_scarr
                                           ( carrid = carr-carrid carrname = carr-carrname ) ).

    " FOR with WHERE
    DATA(lt_carriers_with_usd) = VALUE ltt_carrier( FOR <carr> IN lt_scarr
                                                    WHERE ( currcode = 'USD' )
                                                    ( carrid   = <carr>-carrid
                                                      carrname = <carr>-carrname )  ).

    " FOR with WHERE & CORRESPONDING
    DATA(lt_carriers_with_eur_jpy) = VALUE ltt_carrier( FOR <carr> IN lt_scarr
                                                        WHERE ( currcode = 'EUR' AND
                                                                currcode = 'JPY' )
                                                        " also filling carrid & carrname
                                                        ( CORRESPONDING #( <carr> ) )  ).
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*& REDUCE
    TYPES: BEGIN OF lty_scarr_aggregate,
             carrid  TYPE scarr-carrid,
             flights TYPE int2, " Assuming there is a field indicating a total of flight
           END OF lty_scarr_aggregate,
           ltt_scarr_aggregate TYPE STANDARD TABLE OF lty_scarr_aggregate WITH EMPTY KEY.

    " Example data
    DATA(lt_scarr_aggregate) = VALUE ltt_scarr_aggregate( ( carrid = 'LH' flights = 10 )
                                                          ( carrid = 'AA' flights = 20 )
                                                          ( carrid = 'BA' flights = 30 ) ).

    DATA(lv_total_flights) = REDUCE i( INIT sum = 0
                                        FOR scarr IN lt_scarr_aggregate
                                        NEXT sum = sum + scarr-flights ).

*    out->write( 'Total of flights: ' && lv_total_flights ).
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*& FILTER
    TYPES ltt_scarr2 TYPE STANDARD TABLE OF scarr WITH NON-UNIQUE SORTED KEY carrid
                                                       COMPONENTS carrid.
    " -> iTab must have at least one SORTED or HASHED KEY to use FILTER operator

    DATA lt_scarr_all TYPE ltt_scarr2.

    SELECT FROM scarr
      FIELDS *
      INTO CORRESPONDING FIELDS OF TABLE @lt_scarr_all.

    " Air Berlin only
*   DATA(lt_scarr_ab) = FILTER #( lt_scarr_all USING KEY carrid WHERE carrid = 'AB ' ). " char3
    DATA(lt_scarr_ab) = FILTER #( lt_scarr_all USING KEY carrid
                                               WHERE carrid = CONV #( 'AB' ) ). " explicit convert

    " -> OR is not allowed in WHERE condition due to simplicity. For this -> VALUE (FOR <x> IN itab) or LOOP
*    DATA(lt_scarr_ab_lh) = FILTER #( lt_scarr_all USING KEY carrid WHERE carrid = CONV #( 'AB' ) OR
*                                                                         carrid = CONV #( 'LH' ) ).


    " -> AND is only allowed on the condition not using same key.
*    DATA(lt_scarr_ab_lh) = FILTER #( lt_scarr_all USING KEY carrid WHERE carrid = CONV #( 'AB' ) AND
*                                                                         carrid = CONV #( 'LH' ) ).

    " EXCLUDE Air Berlin
    DATA(lt_scarr_excl_ab) = FILTER #( lt_scarr_all EXCEPT USING KEY carrid
                                                    WHERE carrid = CONV #( 'AB' ) ).

    " FILTER in TABLE Condition - again all entries without Air Berlin
    DATA(lt_scarr_excl_ab2) = FILTER #( lt_scarr_all IN lt_scarr_ab USING KEY carrid
                                                                    WHERE carrid <> carrid ).
*--------------------------------------------------------------------*

  ENDMETHOD.


  METHOD conversions.

    DATA: lv_matnr_without_zero TYPE char15 VALUE '123456789',
          lv_matnr_with_zero    TYPE char15 VALUE '000000123456789'.

*   7.51: New Conversions

*   ALPHA Conversion
    DATA(lv_alpha_in)  = |{ lv_matnr_without_zero ALPHA = IN }|. " adds leading zeros. You can also use it for every conversion which a standard FM does e.g. CONVERSION_EXIT_PARVW_INPUT
*    out->write( lv_alpha_in ).

    DATA(lv_alpha_out) = |{ lv_matnr_with_zero ALPHA = OUT }|.   " removes leading zeros. You can also use it for every conversion which a standard FM does
*    out->write( lv_alpha_out ).


*   Date Format
    " YYYY-MM-DD
*    out->write( |ISO Format : { sy-datum DATE = ISO }| ).
    " as per user setting
*    out->write( |User Format : { sy-datum DATE = USER }| ).
    " Formatting setting of language environment
*    out->write( |Environment Format : { sy-datum DATE = ENVIRONMENT }| ).


*   Time Format
*    out->write( 'Time' ).
*    out->write( |RAW Format:  { sy-uzeit TIME = RAW }| ).
*    out->write( |ISO Format:  { sy-uzeit TIME = ISO }| ).
*    out->write( |User Format: { sy-uzeit TIME = USER }| ).
*    out->write( |Environment Format: { sy-uzeit TIME = USER }| ).


*   TIMESTAMP
    SELECT SINGLE tzonesys FROM ttzcu INTO @DATA(lv_timezone).
    GET TIME STAMP FIELD DATA(lv_timestamp).
*    out->write( 'TIMESTAMP' ).
*    out->write( |'Space Format:'         { lv_timestamp TIMEZONE = lv_timezone TIMESTAMP = SPACE }| ).
*    out->write( |'User Format:'          { lv_timestamp TIMEZONE = lv_timezone TIMESTAMP = USER }| ).
*    out->write( |'ISO Format:'           { lv_timestamp TIMEZONE = lv_timezone TIMESTAMP = ISO }| ).
*    out->write( |'Environment Format:'   { lv_timestamp TIMEZONE = lv_timezone TIMESTAMP = ENVIRONMENT }| ).


*   Case of Text
*    out->write( 'Case of Text' ).
*    out->write( |RAW Format:    { 'Data' CASE = (cl_abap_format=>c_raw) }| ).
*    out->write( |Upper Format:  { 'Data' CASE = (cl_abap_format=>c_upper) }| ).
*    out->write( |Lower Format:  { 'Data' CASE = (cl_abap_format=>c_lower) }| ).


*   Number Format
    DATA(lv_number) = 1234567890.
*    out->write( |Raw Format:         { lv_number NUMBER = (cl_abap_format=>n_raw) }| ).
*    out->write( |User Format:        { lv_number NUMBER = (cl_abap_format=>n_user) }| ).
*    out->write( |Environment Format: { lv_number NUMBER = (cl_abap_format=>n_environment) }| ).

  ENDMETHOD.


  METHOD enhanced_sql_syntax.

    " SELECT with FIELD
    SELECT FROM zahk_po_head_1
      FIELDS COUNT(*)                    AS count_rec,
             COUNT( DISTINCT purch_org ) AS count_org " unique amount of purch. organization
      INTO @DATA(ls_count_po_header).

    " SELECT with Subquery
    SELECT FROM zahk_po_head_1 AS po_header
      FIELDS *
      WHERE EXISTS
        ( SELECT FROM zahk_porg_1
            FIELDS *
            WHERE org = po_header~purch_org )
      INTO TABLE @DATA(lt_po_head_subquery).

    " VALUE within INSERT
    GET TIME STAMP FIELD DATA(lv_timestamp).

    INSERT zahk_porg_1 FROM @( VALUE #( org = 'ORG6'
                                        plant = 'Plant6'
                                        last_changed_timestamp = lv_timestamp ) ).

    INSERT zahk_porg_1 FROM TABLE @(
                            VALUE #( last_changed_timestamp = lv_timestamp " puts in 3 records same value
                                     ( org = 'ORG7' plant = 'Plant7' )
                                     ( org = 'ORG8' plant = 'Plant6' )
                                     ( org = 'ORG9' plant = 'Plant7' ) ) ).

    " JOINS

    " 1. INNER JOIN
    SELECT
      FROM zahk_po_head_1 AS po
             INNER JOIN " or JOIN
               zahk_porg_1 AS porg ON po~purch_org = porg~org
      FIELDS po~purchdoc,
             porg~plant,
             po~netprice
      ORDER BY porg~plant
      INTO TABLE @DATA(lt_inner_join).


    " 2. LEFT OUTER JOIN
    SELECT
      FROM zahk_po_head_1 AS po
             LEFT OUTER JOIN " or LEFT JOIN
               zahk_porg_1 AS porg ON po~purch_org = porg~org
      FIELDS po~purchdoc,
             porg~plant,
             po~netprice
      ORDER BY porg~plant
      INTO TABLE @DATA(lt_left_join).

    " 3. RIGHT OUTER JOIN
    SELECT
      FROM zahk_po_head_1 AS po
             RIGHT OUTER JOIN " or RIGHT JOIN
               zahk_porg_1 AS porg ON po~purch_org = porg~org
      FIELDS po~purchdoc,
             porg~plant,
             po~netprice
      ORDER BY porg~plant
      INTO TABLE @DATA(lt_right_join).

    " UNION
    " -> it joins the output tables of two or more queries in SQL with each other

    " 1. UNION
    SELECT FROM zahk_po_head_1 FIELDS purch_org AS org
     UNION
    SELECT FROM zahk_porg_1    FIELDS org
        INTO TABLE @DATA(lt_union). " with @data -> selected field names must be same(also types)

    " other variant - if some columns not present in second table
    SELECT FROM zahk_po_head_1 FIELDS purch_org AS org,
                                      purchdoc
     UNION
    SELECT FROM zahk_porg_1    FIELDS org,
                                      '-' AS purchdoc " purchdoc doesn't exist in porg_1 table
        INTO TABLE @DATA(lt_union_for_missed_column).

    " 2. UNION ALL
    SELECT FROM zahk_po_head_1 FIELDS purch_org AS org
     UNION ALL " joins every occurring data from selected columns together
    SELECT FROM zahk_porg_1    FIELDS org
        INTO TABLE @DATA(lt_union_all).

    " 3. UNION DISTINCT
    SELECT FROM zahk_po_head_1 FIELDS purch_org AS org
     UNION DISTINCT " joins every unique data from selected columns together
    SELECT FROM zahk_porg_1    FIELDS org
        INTO TABLE @DATA(lt_union_distinct).


    " Aggregation Functions
    SELECT FROM zahk_po_head_1
      FIELDS purch_org,
             SUM( netprice )                AS total_price,
             MAX( netprice )                AS max_price,
             MIN( netprice )                AS min_price,
             AVG( netprice )                AS avg_price,
             AVG( netprice AS DEC( 16,2 ) ) AS avr_price_dec
      GROUP BY purch_org
      ORDER BY total_price
      INTO TABLE @DATA(lt_po_header_grouped).


    " Arithmetic Operations - div, division, floor, round
    SELECT FROM zahk_po_head_1
      FIELDS purchdoc,
             netprice + 10                                         AS cust_netprice,
             ( - netprice ) + 20                                   AS netprice_negative,
             ( netprice + 10 ) * 20                                AS netprice_new,
             " division not possible with types -> int, dec type (solution: div, division)
             CAST( netprice AS FLTP ) / CAST( 100 AS FLTP )        AS netprice_div,
             div( CAST( netprice AS INT4 ), 5 )                    AS netprice_int_div,
             division( ( netprice + 10 ) * 20, 33, 2 )             AS netprice_dec_div,

             ceil( division( ( netprice + 10 ) * 20, 33, 2 ) )     AS ceil,  " 1 round up
             floor( division( ( netprice + 10 ) * 20, 33, 2 ) )    AS floor, " 1 round down
             round( division( ( netprice + 10 ) * 20, 33, 2 ), 1 ) AS round  " round decimal UP & DOWN
      INTO TABLE @DATA(lt_po_arithmetic).


    " SQL String Expressions - DDIC based Tables & CDS Views only
    SELECT FROM zahk_po_head_1
      FIELDS purchdoc,
             upper( description )                           AS uppered,
             lower( description )                           AS lowered,
             length( description )                          AS len_dec,
             concat( description, purch_org )               AS sum_conc,
             concat_with_space( description, purch_org, 2 ) AS sum_conc_space,
             substring( description, 1, 4 )                 AS short_desc, " starting index, how many character
             replace( description, 'Product', 'PRD' )       AS repl_desc,
             lpad( purch_org, 8, '-' )                      AS dec_8_l, " adds - to the left
             rpad( purch_org, 8, '*' )                      AS dec_8_r  " adds * to the right
      INTO TABLE @DATA(lt_po_string_exp).


    " CASE - COALESCE
    SELECT FROM zahk_po_head_1
      FIELDS purchdoc,
             description,
             coalesce( netprice, 0 ) AS netprice, " print 0, if netprice value is NULL
*            coalesce( netprice, netprice1, 0 )   " checks netprice1 if netprice is NULL. Otherwise print 0
             CASE WHEN netprice < 15 THEN 'cheap'
                  WHEN netprice > 15 THEN 'expensive'
                  ELSE 'no price'
             END AS price_comment
      INTO TABLE @DATA(lt_po_case_coalesce).

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    " paste here the code you would like to try and run
  ENDMETHOD.


  METHOD inline_declarations.

*--------------------------------------------------------------------*
*& - DATA
    DATA(lv_number) = 5.          " variable

    SELECT SINGLE FROM scarr
      FIELDS *
      WHERE carrid = 'AA'
      INTO @DATA(ls_scarr).       " structure

    DATA(ls_scarr_copy) = ls_scarr.

    SELECT FROM scarr
      FIELDS *
      WHERE carrid = 'AA'
      INTO TABLE @DATA(lt_scarr). " table

    DATA(lt_scarr_copy) = lt_scarr.
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
*& Field Symbols
    SELECT FROM scarr
      FIELDS *
      INTO TABLE @DATA(lt_scarr2)
      UP TO 2 ROWS.

    LOOP AT lt_scarr2 ASSIGNING FIELD-SYMBOL(<lfs_scarr>).
      <lfs_scarr>-currcode = 'USD'.
    ENDLOOP.

*& LOOP - REFERENCE INTO DATA
    LOOP AT lt_scarr2 REFERENCE INTO DATA(lr_scarr).
      lr_scarr->currcode = 'EUR'. " - works same as field symbols
    ENDLOOP.                      " - FS offers more performance in tables
    " with more entries
*--------------------------------------------------------------------*

  ENDMETHOD.


  METHOD internal_table_expressions.

    SELECT FROM scarr
        FIELDS *
        INTO TABLE @DATA(lt_scarr).

    " fetching whole data line(structure) of Lufthansa
    " -> if no record is found, throws exception -> cx_sy_itab_line_not_found
    " either handle exception via TRY-CATCH or use VALUE #( .. OPTIONAL ) to avoid dump
    DATA(ls_lufthansa)     = lt_scarr[ carrid = 'LH' ].
    DATA(ls_lufthansa_opt) = VALUE #( lt_scarr[ carrid = 'LH' ] OPTIONAL ).

    " fetching a specific column data of Lufthansa
    DATA(lv_lufthansa_carrid) = lt_scarr[ carrid = 'LH' ]-carrid.

    " whether a specific carrier exists (e.g. Lufthansa)
    " -> in IF condition no need for xsdbool -> IF line_exists( lt_scarr[ carrid = 'LH' ] )...
    DATA(lv_lufthansa_exists) = xsdbool( line_exists( lt_scarr[ carrid = 'LH' ] ) ).

    " index of Lufthansa (returns 0 in case of no record found)
    DATA(lv_lv_lufthansa_index) = line_index( lt_scarr[ carrid = 'LH' ] ).

  ENDMETHOD.


  METHOD loop_at_group_by.

    SELECT FROM scarr
      FIELDS *
      INTO TABLE @DATA(lt_scarr).

    " Group by currency
    LOOP AT lt_scarr INTO DATA(ls_scarr) GROUP BY ls_scarr-currcode. " can be extended ASCENDING / DESCENDING

    ENDLOOP.

    " Group by more fields
    LOOP AT lt_scarr INTO ls_scarr GROUP BY ( carrid   = ls_scarr-carrid  " explicit field specification needed
                                              currcode = ls_scarr-currcode ).

    ENDLOOP.

    " Group by currency EUR or USD
    LOOP AT lt_scarr INTO ls_scarr WHERE    currcode = 'EUR'
                                         OR currcode = 'USD'
                                   GROUP BY ls_scarr-currcode.

    ENDLOOP.

    " with Field-Symbol
    LOOP AT lt_scarr ASSIGNING FIELD-SYMBOL(<lfs_scarr>) GROUP BY <lfs_scarr>-currcode.

    ENDLOOP.

    " with REFERENCE INTO
    LOOP AT lt_scarr REFERENCE INTO DATA(lr_scarr) GROUP BY lr_scarr->*-carrid.
      " or GROUP BY lr_scarr->carrid
    ENDLOOP.

  ENDMETHOD.


  METHOD type_checking.

    DATA: lo_if_type_check TYPE REF TO zif_test_type_checking.

    lo_if_type_check = CAST #( NEW zcl_abap_new_syntax(  ) ).

*    -> to confirm the object's specific class type / instance type
*    -> or when dealing with inheritance hierarchies
*       where multiple classes implement the same interface

    " IS INSTANCE OF
    IF lo_if_type_check IS INSTANCE OF zcl_abap_new_syntax.
*      out->write( 'IS INSTANCE OF -> zcl_abap_new_syntax' ).
    ENDIF.

    " CASE TYPE OF
    CASE TYPE OF lo_if_type_check.
      WHEN TYPE zcl_abap_new_syntax INTO DATA(lo_optional).
*        out->write( 'CASE TYPE OF -> zcl_abap_new_syntax' ).
      WHEN OTHERS.
*        out->write( 'Other type/instance' ).
    ENDCASE.

    " Other variants
    " -> Utility Classes might be beneficial in more dynamic scenarios
    " (e.g. determining class from a configuration at runtime)
    IF abap_true = cl_lcr_util=>instanceof( object = lo_if_type_check
                                            class = 'zcl_abap_new_syntax' ).
*      out->write( 'variant 3 -> zcl_abap_new_syntax' ).
    ENDIF.

    IF abap_true = cl_wdy_wb_reflection_helper=>is_instance_of( object    = lo_if_type_check
                                                                type_name = 'zcl_abap_new_syntax' ).
*      out->write( 'variant 4 -> zcl_abap_new_syntax' ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
