CLASS zcl_demo_random DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS class_constructor.

    METHODS constructor
      IMPORTING id_min TYPE i DEFAULT 1
                id_max TYPE i DEFAULT 6.

    METHODS rand
      RETURNING VALUE(rd_rand) TYPE i.

  PRIVATE SECTION.
    CLASS-DATA mo_seed TYPE REF TO cl_abap_random.

    DATA mo_rand TYPE REF TO cl_abap_random.
    DATA md_from TYPE i.
    DATA md_to   TYPE i.
ENDCLASS.


CLASS zcl_demo_random IMPLEMENTATION.
  METHOD class_constructor.
    TRY.
        DATA(ld_date) = cl_abap_context_info=>get_system_date( ).
        DATA(ld_time) = cl_abap_context_info=>get_system_time( ).

        DATA(ld_seed) = CONV i( |{ ld_date+4 }{ ld_time }| ).
      CATCH cx_sy_conversion_overflow.
        ld_seed = 1337.
    ENDTRY.

    mo_seed = cl_abap_random=>create( ld_seed ).
  ENDMETHOD.

  METHOD constructor.
    md_from = id_min.
    md_to = id_max.

    mo_rand = cl_abap_random=>create( mo_seed->intinrange( low  = 1
                                                           high = 10000 ) ).
  ENDMETHOD.

  METHOD rand.
    rd_rand = mo_rand->intinrange( low  = md_from
                                   high = md_to ).
  ENDMETHOD.
ENDCLASS.
