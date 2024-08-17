CLASS zcl_demo_filtering DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES: BEGIN OF ts_data,
             identifier TYPE i,
             payload    TYPE string,
             sdate      TYPE d,
           END OF ts_data.
    TYPES tt_data TYPE STANDARD TABLE OF ts_data WITH EMPTY KEY
          WITH NON-UNIQUE SORTED KEY by_date COMPONENTS sdate.

  PRIVATE SECTION.
    CONSTANTS c_table_entries TYPE i VALUE 500000.

    DATA mt_data          TYPE tt_data.
    DATA md_random_filter TYPE d.

    METHODS prepare_random_data.

    METHODS run_basic_loop_data
      RETURNING VALUE(rd_result) TYPE i.

    METHODS run_basic_loop_assigning
      RETURNING VALUE(rd_result) TYPE i.

    METHODS run_loop_with_key
      RETURNING VALUE(rd_result) TYPE i.

    METHODS run_filter_and_lines
      RETURNING VALUE(rd_result) TYPE i.

    METHODS run_reduce
      RETURNING VALUE(rd_result) TYPE i.

    METHODS run_for_lines
      RETURNING VALUE(rd_result) TYPE i.
ENDCLASS.


CLASS zcl_demo_filtering IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    prepare_random_data( ).

    " ..Basic Loop
    DATA(lo_run) = NEW zcl_demo_runtime_measure( ).
    DATA(ld_count) = run_basic_loop_data( ).
    out->write( |Basic Loop (DATA) - { ld_count }     : { lo_run->get_diff( ) }| ).

    " ..Loop Assigning
    lo_run = NEW zcl_demo_runtime_measure( ).
    ld_count = run_basic_loop_assigning( ).
    out->write( |Basic Loop (ASSIGNING) - { ld_count }: { lo_run->get_diff( ) }| ).

    " ..Loop with Key
    lo_run = NEW zcl_demo_runtime_measure( ).
    ld_count = run_loop_with_key( ).
    out->write( |Loop with key - { ld_count }         : { lo_run->get_diff( ) }| ).

    " ..FILTER
    lo_run = NEW zcl_demo_runtime_measure( ).
    ld_count = run_filter_and_lines( ).
    out->write( |Filter and Lines - { ld_count }      : { lo_run->get_diff( ) }| ).

    " ..REDUCE
    lo_run = NEW zcl_demo_runtime_measure( ).
    ld_count = run_reduce( ).
    out->write( |Reduce - { ld_count }                : { lo_run->get_diff( ) }| ).

    " ..FOR
    lo_run = NEW zcl_demo_runtime_measure( ).
    ld_count = run_for_lines( ).
    out->write( |FOR and Lines - { ld_count }         : { lo_run->get_diff( ) }| ).
  ENDMETHOD.

  METHOD prepare_random_data.
    DATA(lo_random_date) = NEW zcl_demo_random( id_min = 0
                                                id_max = 180 ).
    DATA(lo_random_string) = NEW zcl_demo_random( id_min = 1
                                                  id_max = 6 ).

    DO c_table_entries TIMES.
      INSERT VALUE #( identifier = sy-index
                      payload    = SWITCH #( lo_random_string->rand( )
                                             WHEN 1 THEN `My text is alone`
                                             WHEN 2 THEN `Second entry of this`
                                             WHEN 3 THEN `What you need`
                                             WHEN 4 THEN `The long summer`
                                             WHEN 5 THEN `Advertising your next project`
                                             WHEN 6 THEN `A rainy day` )
                      sdate      = CONV d( cl_abap_context_info=>get_system_date( ) - lo_random_date->rand( ) ) )
             INTO TABLE mt_data.
    ENDDO.

    md_random_filter = cl_abap_context_info=>get_system_date( ) - lo_random_date->rand( ).
  ENDMETHOD.

  METHOD run_basic_loop_data.
    LOOP AT mt_data INTO DATA(ls_data) WHERE sdate = md_random_filter.
      rd_result += 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD run_basic_loop_assigning.
    LOOP AT mt_data ASSIGNING FIELD-SYMBOL(<ls_data>) WHERE sdate = md_random_filter.
      rd_result += 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD run_loop_with_key.
    LOOP AT mt_data ASSIGNING FIELD-SYMBOL(<ls_data>) USING KEY by_date WHERE sdate = md_random_filter.
      rd_result += 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD run_filter_and_lines.
    rd_result = lines( FILTER #( mt_data USING KEY by_date WHERE sdate = md_random_filter ) ).
  ENDMETHOD.

  METHOD run_reduce.
    rd_result = REDUCE #(
      INIT ld_count TYPE i
      FOR <ls_data> IN mt_data USING KEY by_date WHERE ( sdate = md_random_filter )
      NEXT ld_count += 1 ).
  ENDMETHOD.

  METHOD run_for_lines.
    rd_result = lines( VALUE tt_data( FOR <ls_data> IN mt_data USING KEY by_date WHERE ( sdate = md_random_filter )
                                      ( CORRESPONDING #( <ls_data> ) ) ) ).
  ENDMETHOD.
ENDCLASS.
