! THIS VERSION: CUTEST 1.0 - 17/11/2012 AT 17:00 GMT.

!-*- C U T E S T  t e s t _ c o n s t r a i n e d _ t o o l s  P R O G R A M -*-

    PROGRAM CUTEST_test_constrained_tools

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal author: Nick Gould

!  History -
!   fortran 2003 version released November 2012

      USE CUTEST

!--------------------
!   P r e c i s i o n
!--------------------

      INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )

!----------------------
!   P a r a m e t e r s
!----------------------

      INTEGER, PARAMETER :: input = 55
      INTEGER, PARAMETER :: out = 6
      INTEGER, PARAMETER :: buffer = 77 
      REAL ( KIND = wp ), PARAMETER :: one = 1.0_wp

!--------------------------------
!   L o c a l   V a r i a b l e s
!--------------------------------

      INTEGER :: n, m, H_ne, HE_nel, HE_val_ne, HE_row_ne, J_ne, Ji_ne, status
      INTEGER :: l_h2_1, l_h, lhe_ptr, lhe_val, lhe_row, alloc_stat
      REAL ( KIND = wp ) :: f, ci
      LOGICAL :: grad, byrows, goth, efirst, lfirst, nvfrst, grlagf, jtrans
      CHARACTER ( len = 10 ) ::  p_name
      INTEGER, ALLOCATABLE, DIMENSION( : ) :: H_row, H_col, X_type
      INTEGER, ALLOCATABLE, DIMENSION( : ) :: HE_row, HE_row_ptr, HE_val_ptr
      INTEGER, ALLOCATABLE, DIMENSION( : ) :: J_var, J_fun
      REAL ( KIND = wp ), ALLOCATABLE, DIMENSION( : ) :: X, X_l, X_u, G, Ji
      REAL ( KIND = wp ), ALLOCATABLE, DIMENSION( : ) :: Y, C_l, C_u, C, J_val
      REAL ( KIND = wp ), ALLOCATABLE, DIMENSION( : ) :: H_val, HE_val
      REAL ( KIND = wp ), ALLOCATABLE, DIMENSION( : ) :: VECTOR, RESULT
      REAL ( KIND = wp ), ALLOCATABLE, DIMENSION( : , : ) :: H2_val
      REAL ( KIND = wp ), ALLOCATABLE, DIMENSION( : , : ) :: J2_val
      LOGICAL, ALLOCATABLE, DIMENSION( : ) :: EQUATION, LINEAR
      CHARACTER ( len = 10 ), ALLOCATABLE, DIMENSION( : ) :: X_names, C_names
!     REAL :: CPU( 2 ), CALLS( 4 )
      TYPE ( CUTEST_data_type ) :: data

!  open the problem data file

      OPEN ( input, FILE = 'c_OUTSDIF.d', FORM = 'FORMATTED', STATUS = 'OLD' )

!  allocate basic arrays

      WRITE( out, "( ' CALL CUTEST_cdimen ' )" )
      CALL CUTEST_cdimen( input, status, n, m )
      WRITE( out, "( ' * n = ', I0, ', m = ', I0 )" ) n, m
      l_h2_1 = n
      ALLOCATE( X( n ), X_l( n ), X_u( n ), G( n ), VECTOR( n ), Ji( n ),      &
                RESULT( n ), X_names( n ), X_type( n ), stat = alloc_stat )
      IF ( alloc_stat /= 0 ) GO TO 990
      ALLOCATE( C( m ), Y( m ), C_l( m ), C_u( m ), C_names( m ),              &
                EQUATION( m ), LINEAR( m ), stat = alloc_stat )
      IF ( alloc_stat /= 0 ) GO TO 990
      ALLOCATE( H2_val( l_h2_1, n ), stat = alloc_stat )
      IF ( alloc_stat /= 0 ) GO TO 990
      l_j2_1 = MAX( m, n ) ; l_j2_2 = l_j2_1      
      ALLOCATE( J2_val( l_j2_1, l_j2_2 ), stat = alloc_stat )
      IF ( alloc_stat /= 0 ) GO TO 990

!  set up SIF data

      efirst = .TRUE. ; lfirst = .TRUE. ; nvfrst = .TRUE.
      WRITE( out, "( ' CALL CUTEST_csetup ' )" )
      CALL CUTEST_csetup( data, status, input, out, buffer, n, m, X, X_l, X_u, &
                      Y, C_l, C_u, EQUATION, LINEAR, efirst, lfirst, nvfrst )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_X( out, n, X, X_l, X_u )
      CALL WRITE_Y( out, m, Y, C_l, C_u, EQUATION, LINEAR )

X = (/ 1.1_wp, 2.2_wp, 3.3_wp, 4.4_wp /)

!  obtain variable and problem names

      WRITE( out, "( ' CALL CUTEST_cnames' )" )
      CALL CUTEST_cnames( data, status, n, m, p_name, X_names, C_names )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_p_name( out, p_name )
      CALL WRITE_X_names( out, n, X_names )
      CALL WRITE_C_names( out, m, C_names )

!  obtain constraint names

      WRITE( out, "( ' Call CUTEST_connames' )" )
      CALL CUTEST_connames( data, status, m, C_names )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_C_names( out, m, C_names )

!  obtain variable types

      WRITE( out, "( ' CALL CUTEST_cvartype' )" )
      CALL CUTEST_cvartype( data, status, n, X_type )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_X_type( out, n, X_type )

!  compute the objective function value

      WRITE( out, "( ' CALL CUTEST_cfn' )" )
      CALL CUTEST_cfn( data, status, n, m, X, f, C )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_f( out, f )
      CALL WRITE_C( out, m, C )

!  compute the gradient and dense Jacobian values

      grlagf = .TRUE. ; jtrans = .TRUE.
      WRITE( out, "( ' CALL CUTEST_cgr with grlagf = .TRUE. and ',             &
     &               'jtrans = .TRUE.' )" )
      CALL CUTEST_cgr( data, status, n, m, X, Y, grlagf, G, jtrans,            &
                l_j2_1, l_j2_2, J2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_G( out, n, G )
      CALL WRITE_JT_dense( out, n, m, l_j2_1, l_j2_2, J2_val )
      grlagf = .TRUE. ; jtrans = .FALSE.
      WRITE( out, "( ' CALL CUTEST_cgr with grlagf = .TRUE. and ',             &
     &               'jtrans = .FALSE.' )" )
      CALL CUTEST_cgr( data, status, n, m, X, Y, grlagf, G, jtrans,            &
                l_j2_1, l_j2_2, J2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_G( out, n, G )
      CALL WRITE_J_dense( out, n, m, l_j2_1, l_j2_2, J2_val )
      grlagf = .FALSE. ; jtrans = .TRUE.
      WRITE( out, "( ' CALL CUTEST_cgr with grlagf = .FALSE. and ',            &
     &               'jtrans = .TRUE.' )" )
      CALL CUTEST_cgr( data, status, n, m, X, Y, grlagf, G, jtrans,            &
                l_j2_1, l_j2_2, J2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_G( out, n, G )
      CALL WRITE_JT_dense( out, n, m, l_j2_1, l_j2_2, J2_val )
      grlagf = .FALSE. ; jtrans = .FALSE.
      WRITE( out, "( ' CALL CUTEST_cgr with grlagf = .FALSE. and ',            &
     &               'jtrans = .FALSE.' )" )
      CALL CUTEST_cgr( data, status, n, m, X, Y, grlagf, G, jtrans,            &
                l_j2_1, l_j2_2, J2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_G( out, n, G )
      CALL WRITE_J_dense( out, n, m, l_j2_1, l_j2_2, J2_val )

!  compute the objective function and gradient values

      grad = .TRUE.
      WRITE( out, "( ' CALL CUTEST_cofg with grad = .TRUE.' )" )
      CALL CUTEST_cofg( data, status, n, X, f, G, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_f( out, f )
      CALL WRITE_G( out, n, G )
      grad = .FALSE.
      WRITE( out, "( ' CALL CUTEST_cofg with grad = .FALSE.' )" )
      CALL CUTEST_cofg( data, status, n, X, f, G, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_f( out, f )

!  compute the number of nonzeros in the sparse Jacobian

      WRITE( out, "( ' CALL CUTEST_cdimsj' )" )
      CALL CUTEST_cdimsj( data, status, J_ne )
      IF ( status /= 0 ) GO to 900
      WRITE( out, "( ' * J_ne = ', I0 )" ) J_ne

      l_j = J_ne
      ALLOCATE( J_val( l_j ), J_fun( l_j ), J_var( l_j ), stat = alloc_stat )
      IF ( alloc_stat /= 0 ) GO TO 990

!  compute the gradient and sparse Jacobian values

      grlagf = .TRUE.
      WRITE( out, "( ' CALL CUTEST_csgr with grlagf = .TRUE.' )" )
      CALL CUTEST_csgr( data, status, n, m, X, Y, grlagf,                      &
                 J_ne, l_j, J_val, J_var, J_fun )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )
      grlagf = .FALSE.
      WRITE( out, "( ' CALL CUTEST_csgr with grlagf = .FALSE.' )" )
      CALL CUTEST_csgr( data, status, n, m, X, Y, grlagf,                      &
                 J_ne, l_j, J_val, J_var, J_fun )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )

!  compute the constraint and dense Jacobian values

      grad = .TRUE. ; jtrans = .TRUE.
      WRITE( out, "( ' CALL CUTEST_ccfg with grad = .TRUE. and ',              &
     &               'jtrans = .TRUE.' )" )
      CALL CUTEST_ccfg( data, status, n, m, X, C, jtrans,                      &
                 l_j2_1, l_j2_2, J2_val, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_C( out, m, C )
      CALL WRITE_JT_dense( out, n, m, l_j2_1, l_j2_2, J2_val )
      grad = .TRUE. ; jtrans = .FALSE.
      WRITE( out, "( ' CALL CUTEST_ccfg with grad = .TRUE. and ',              &
     &               'jtrans = .FALSE.' )" )
      CALL CUTEST_ccfg( data, status, n, m, X, C, jtrans,                      &
                 l_j2_1, l_j2_2, J2_val, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_C( out, m, C )
      CALL WRITE_J_dense( out, n, m, l_j2_1, l_j2_2, J2_val )
      grad = .FALSE. ; jtrans = .TRUE.
      WRITE( out, "( ' CALL CUTEST_ccfg with grad = .FALSE. and ',             &
     &               'jtrans = .TRUE.' )" )
      CALL CUTEST_ccfg( data, status, n, m, X, C, jtrans,                      &
                 l_j2_1, l_j2_2, J2_val, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_C( out, m, C )
      grad = .FALSE. ; jtrans = .FALSE.
      WRITE( out, "( ' CALL CUTEST_ccfg with grad = .FALSE. and ',             &
     &               'jtrans = .FALSE.' )" )
      CALL CUTEST_ccfg( data, status, n, m, X, C, jtrans,                      &
                 l_j2_1, l_j2_2, J2_val, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_C( out, m, C )

!  compute the constraint and sparse Jacobian values ....

      grad = .TRUE.
      WRITE( out, "( ' CALL CUTEST_cscfg with grad = .TRUE.' )" )
      CALL CUTEST_cscfg( data, status, n, m, X, C,                             &
                         J_ne, l_j, J_val, J_var, J_fun, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_C( out, m, C )
      CALL WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )
      grad = .FALSE.
      WRITE( out, "( ' CALL CUTEST_cscfg with grad = .FALSE.' )" )
      CALL CUTEST_cscfg( data, status, n, m, X, C,                             &
                         J_ne, l_j, J_val, J_var, J_fun, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_C( out, m, C )

!  ... and its current version

      grad = .TRUE.
      WRITE( out, "( ' CALL CUTEST_ccfsg with grad = .TRUE.' )" )
      CALL CUTEST_ccfsg( data, status, n, m, X, C,                             &
                         J_ne, l_j, J_val, J_var, J_fun, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_C( out, m, C )
      CALL WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )
      grad = .FALSE.
      WRITE( out, "( ' CALL CUTEST_ccfsg with grad = .FALSE.' )" )
      CALL CUTEST_ccfsg( data, status, n, m, X, C,                             &
                         J_ne, l_j, J_val, J_var, J_fun, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_C( out, m, C )

!  compute an individual constraint and its dense gradient

      icon = 1
      grad = .TRUE.
      WRITE( out, "( ' CALL CUTEST_ccifg with grad = .TRUE.' )" )
      CALL CUTEST_ccifg( data, status, n, icon, X, ci, Ji, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_CI( out, icon, ci )
      CALL WRITE_JI( out, n, icon, Ji )
      grad = .FALSE.
      WRITE( out, "( ' CALL CUTEST_ccifg with grad = .FALSE.' )" )
      CALL CUTEST_ccifg( data, status, n, icon, X, ci, Ji, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_CI( out, icon, ci )

!  compute an individual constraint and its sparse gradient ....

      grad = .TRUE.
      WRITE( out, "( ' CALL CUTEST_cscifg with grad = .TRUE.' )" )
      CALL CUTEST_cscifg( data, status, n, icon, X, ci,                        &
                          Ji_ne, n, Ji, J_var, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_CI( out, icon, ci )
      CALL WRITE_SJI( out, icon, Ji_ne, n, Ji, J_var )
      grad = .FALSE.
      WRITE( out, "( ' CALL CUTEST_cscifg with grad = .FALSE.' )" )
      CALL CUTEST_cscifg( data, status, n, icon, X, ci,                        &
                          Ji_ne, n, Ji, J_var, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_CI( out, icon, ci )

!  ... and its current version

      grad = .TRUE.
      WRITE( out, "( ' CALL CUTEST_ccifsg with grad = .TRUE.' )" )
      CALL CUTEST_ccifsg( data, status, n, icon, X, ci,                        &
                          Ji_ne, n, Ji, J_var, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_CI( out, icon, ci )
      CALL WRITE_SJI( out, icon, Ji_ne, n, Ji, J_var )
      grad = .FALSE.
      WRITE( out, "( ' CALL CUTEST_ccifsg with grad = .FALSE.' )" )
      CALL CUTEST_ccifsg( data, status, n, icon, X, ci,                        &
                          Ji_ne, n, Ji, J_var, grad )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_CI( out, icon, ci )

!  compute the dense Hessian value

      WRITE( out, "( ' CALL CUTEST_cdh' )" )
      CALL CUTEST_cdh( data, status, n, m, X, Y, l_h2_1, H2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_H_dense( out, n, l_h2_1, H2_val )

!  compute the dense Hessian value of the objective or a constraint

      iprob = 0
      WRITE( out, "( ' CALL CUTEST_cidh for objective' )" )
      CALL CUTEST_cidh( data, status, n, X, iprob, l_h2_1, H2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_H_dense( out, n, l_h2_1, H2_val )
      iprob = 1
      WRITE( out, "( ' CALL CUTEST_cidh for a constraint' )" )
      CALL CUTEST_cidh( data, status, n, X, iprob, l_h2_1, H2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_H_dense( out, n, l_h2_1, H2_val )

!  compute the gradient and dense Hessian values

      grlagf = .TRUE. ; jtrans = .TRUE.
      WRITE( out, "( ' CALL CUTEST_cgrdh with grlagf = .TRUE. and ',           &
     &               'jtrans = .TRUE.' )" )
      CALL CUTEST_cgrdh( data, status, n, m, X, Y, grlagf, G, jtrans,          &
                  l_j2_1, l_j2_2, J2_val, l_h2_1, H2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_G( out, n, G )
      CALL WRITE_H_dense( out, n, l_h2_1, H2_val )
      grlagf = .TRUE. ; jtrans = .FALSE.
      WRITE( out, "( ' CALL CUTEST_cgrdh with grlagf = .TRUE. and ',           &
     &               'jtrans = .FALSE.' )")
      CALL CUTEST_cgrdh( data, status, n, m, X, Y, grlagf, G, jtrans,          &
                  l_j2_1, l_j2_2, J2_val, l_h2_1, H2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_G( out, n, G )
      CALL WRITE_H_dense( out, n, l_h2_1, H2_val )
      grlagf = .FALSE. ; jtrans = .TRUE.
      WRITE( out, "( ' CALL CUTEST_cgrdh with grlagf = .FALSE. and ',          &
     &               'jtrans = .TRUE.' )")
      CALL CUTEST_cgrdh( data, status, n, m, X, Y, grlagf, G, jtrans,          &
                  l_j2_1, l_j2_2, J2_val, l_h2_1, H2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_G( out, n, G )
      CALL WRITE_H_dense( out, n, l_h2_1, H2_val )
      grlagf = .FALSE. ; jtrans = .FALSE.
      WRITE( out, "( ' CALL CUTEST_cgrdh with grlagf = .FALSE. and ',          &
     &               'jtrans = .FALSE.')")
      CALL CUTEST_cgrdh( data, status, n, m, X, Y, grlagf, G, jtrans,          &
                  l_j2_1, l_j2_2, J2_val, l_h2_1, H2_val )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_G( out, n, G )
      CALL WRITE_H_dense( out, n, l_h2_1, H2_val )

!  compute the number of nonzeros in the sparse Hessian

      WRITE( out, "( ' CALL CUTEST_cdimsh' )" )
      CALL CUTEST_cdimsh( data, status, H_ne )
      IF ( status /= 0 ) GO to 900
      WRITE( out, "( ' * H_ne = ', I0 )" ) H_ne

      l_h = H_ne
      ALLOCATE( H_val( l_h ), H_row( l_h ), H_col( l_h ), stat = alloc_stat )
      IF ( alloc_stat /= 0 ) GO TO 990

!  compute the sparse Hessian value

      WRITE( out, "( ' CALL CUTEST_csh' )" )
      CALL CUTEST_csh( data, status, n, m, X, Y,                               &
                       H_ne, l_h, H_val, H_row, H_col )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_H_sparse( out, H_ne, l_h, H_val, H_row, H_col )

!  compute the sparse Hessian value without the objective

      WRITE( out, "( ' CALL CUTEST_cshc' )" )
      CALL CUTEST_cshc( data, status, n, m, X, Y,                              &
                        H_ne, l_h, H_val, H_row, H_col )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_H_sparse( out, H_ne, l_h, H_val, H_row, H_col )

!  compute the sparse Hessian value of the objective or a constraint

      iprob = 0
      WRITE( out, "( ' CALL CUTEST_cish for objective' )" )
      CALL CUTEST_cish( data, status, n, X, iprob,                             &
                        H_ne, l_h, H_val, H_row, H_col )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_H_sparse( out, H_ne, l_h, H_val, H_row, H_col )
      iprob = 1
      WRITE( out, "( ' CALL CUTEST_cish for a constraint' )" )
      CALL CUTEST_cish( data, status, n, X, iprob,                             &
                        H_ne, l_h, H_val, H_row, H_col )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_H_sparse( out, H_ne, l_h, H_val, H_row, H_col )

!  compute the gradient and sparse Hessian values

      grlagf = .TRUE.
      WRITE( out, "( ' CALL CUTEST_csgrsh with grlagf = .TRUE.' )" )
      CALL CUTEST_csgrsh( data, status, n, m, X, Y, grlagf, J_ne, l_j, J_val,  &
                   J_var, J_fun, H_ne, l_h, H_val, H_row, H_col )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )
      CALL WRITE_H_sparse( out, H_ne, l_h, H_val, H_row, H_col )
      grlagf = .FALSE.
      WRITE( out, "( ' CALL CUTEST_csgrsh with grlagf = .FALSE.' )" )
      CALL CUTEST_csgrsh( data, status, n, m, X, Y, grlagf, J_ne, l_j, J_val,  &
                   J_var, J_fun, H_ne, l_h, H_val, H_row, H_col )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )
      CALL WRITE_H_sparse( out, H_ne, l_h, H_val, H_row, H_col )

!  compute the number of nonzeros in the element Hessian

      WRITE( out, "( ' CALL CUTEST_cdimse' )" )
      CALL CUTEST_cdimse( data, status, HE_nel, HE_val_ne, HE_row_ne )
      IF ( status /= 0 ) GO to 900
      WRITE( out, "( ' * H_nel = ', I0, ' HE_val_ne = ', I0,                   &
     &                 ' HE_row_ne = ', I0 )" ) HE_nel, HE_val_ne, HE_row_ne

      lhe_ptr = HE_nel + 1
      lhe_val = HE_val_ne
      lhe_row = HE_row_ne
      ALLOCATE( HE_row_ptr( lhe_ptr ), HE_val_ptr( lhe_ptr ),                  &
                HE_row( lhe_row ),  HE_val( lhe_val ), stat = alloc_stat )
      IF ( alloc_stat /= 0 ) GO TO 990

!  compute the element Hessian value

      byrows = .FALSE.
      WRITE( out, "( ' CALL CUTEST_ceh with byrows = .FALSE.' )" )
      CALL CUTEST_ceh( data, status, n, m, X, Y, HE_nel, lhe_ptr, HE_row_ptr,  &
                HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val, byrows )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_H_element( out, HE_nel, lhe_ptr, HE_row_ptr,                  &
                            HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val )
      byrows = .TRUE.
      WRITE( out, "( ' CALL CUTEST_ceh with byrows = .TRUE.' )" )
      CALL CUTEST_ceh( data, status, n, m, X, Y, HE_nel, lhe_ptr, HE_row_ptr,  &
                HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val, byrows )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_H_element( out, HE_nel, lhe_ptr, HE_row_ptr,                  &
                            HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val )

!  compute the gradient and element Hessian values

      grlagf = .TRUE. ; byrows = .TRUE.
      WRITE( out, "( ' CALL CUTEST_csgreh with grlagf = .TRUE. and ',          &
     &               'byrows = .TRUE.')" )
      CALL CUTEST_csgreh( data, status, n, m, X, Y, grlagf, J_ne, l_j,         &
                   J_val, J_var, J_fun, HE_nel, lhe_ptr, HE_row_ptr,           &
                   HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val, byrows )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )
      CALL WRITE_H_element( out, HE_nel, lhe_ptr, HE_row_ptr,                  &
                            HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val )
      grlagf = .TRUE. ; byrows = .FALSE.
      WRITE( out, "(' CALL CUTEST_csgreh with grlagf = .TRUE. and ',           &
     &               'byrows = .FALSE.')" )
      CALL CUTEST_csgreh( data, status, n, m, X, Y, grlagf, J_ne, l_j,         &
                   J_val, J_var, J_fun, HE_nel, lhe_ptr, HE_row_ptr,           &
                   HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val, byrows )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )
      CALL WRITE_H_element( out, HE_nel, lhe_ptr, HE_row_ptr,                  &
                            HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val )
      grlagf = .FALSE. ; byrows = .TRUE.
      WRITE( out, "( ' CALL CUTEST_csgreh with grlagf = .FALSE. and ',         &
     &               'byrows = .TRUE.')")
      CALL CUTEST_csgreh( data, status, n, m, X, Y, grlagf, J_ne, l_j,         &
                   J_val, J_var, J_fun, HE_nel, lhe_ptr, HE_row_ptr,           &
                   HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val, byrows )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )
      CALL WRITE_H_element( out, HE_nel, lhe_ptr, HE_row_ptr,                  &
                            HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val )
      grlagf = .FALSE. ; byrows = .FALSE.
      WRITE( out, "(' CALL CUTEST_csgreh with grlagf = .FALSE. and ',          &
     &               'byrows = .FALSE.')")
      CALL CUTEST_csgreh( data, status, n, m, X, Y, grlagf, J_ne, l_j,         &
                   J_val, J_var, J_fun, HE_nel, lhe_ptr, HE_row_ptr,           &
                   HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val, byrows )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )
      CALL WRITE_H_element( out, HE_nel, lhe_ptr, HE_row_ptr,                  &
                            HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val )

!  compute a Hessian-vector product

      VECTOR = one
      goth = .FALSE.
      WRITE( out, "( ' Call CUTEST_chprod with goth = .FALSE.' )" )
      CALL CUTEST_chprod( data, status, n, m, goth, X, Y, VECTOR, RESULT )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_RESULT( out, n, VECTOR, RESULT )
      goth = .TRUE.
      WRITE( out, "( ' Call CUTEST_chprod with goth = .TRUE.' )" )
      CALL CUTEST_chprod( data, status, n, m, goth, X, Y, VECTOR, RESULT )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_RESULT( out, n, VECTOR, RESULT )

!  compute a Hessian-vector product ignoring the objective

      VECTOR = one
      goth = .FALSE.
      WRITE( out, "( ' Call CUTEST_chcprod with goth = .FALSE.' )" )
      CALL CUTEST_chcprod( data, status, n, m, goth, X, Y, VECTOR, RESULT )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_RESULT( out, n, VECTOR, RESULT )
      goth = .TRUE.
      WRITE( out, "( ' Call CUTEST_chcprod with goth = .TRUE.' )" )
      CALL CUTEST_chcprod( data, status, n, m, goth, X, Y, VECTOR, RESULT )
      IF ( status /= 0 ) GO to 900
      CALL WRITE_RESULT( out, n, VECTOR, RESULT )

!  terminal exit

!     WRITE( out, "( ' CALL CUTEST_creport' )" )
!     CALL CUTEST_creport( CALLS, CPU )

      DEALLOCATE( X_type, H_row, H_col, HE_row, HE_row_ptr, HE_val_ptr, X,     &
                  X_l, X_u, G, Ji, Y, C_l, C_u, C, H_val, HE_val, H2_val,      &
                  J_val, J_var, J_fun, J2_val, VECTOR, RESULT,                 &
                  X_names, C_names, EQUATION, LINEAR, stat = alloc_stat )
      CLOSE( input )
      STOP

!  error exits

 900  CONTINUE
      WRITE( out, "( ' error status = ', I0 )" ) status
      CLOSE( INPUT  )
      STOP

 990  CONTINUE
      WRITE( out, "( ' Allocation error, status = ', I0 )" ) alloc_stat
      CLOSE( INPUT  )
      STOP

    CONTAINS

!  data printing subroutines

      SUBROUTINE WRITE_X( out, n, X, X_l, X_u )
      INTEGER :: n, out
      REAL ( KIND = wp ), DIMENSION( n ) :: X, X_l, X_u
      WRITE( out, "( ' *       i      X_l          X          X_u' )" )
      DO i = 1, n
        WRITE( out, "( ' * ', I7, 3ES12.4 )" ) i, X_l( i ), X( i ), X_u( i )
      END DO
      END SUBROUTINE WRITE_X

      SUBROUTINE WRITE_Y( out, m, Y, C_l, C_u, EQUATION, LINEAR )
      INTEGER :: m, out
      REAL ( KIND = wp ), DIMENSION( m ) :: Y, C_l, C_u
      LOGICAL, DIMENSION( m ) :: EQUATION, LINEAR
      WRITE( out, "( ' *       i      C_l         C_u          Y   ',          &
    &   '      EQUATION   LINEAR' )" )
      DO i = 1, m
        WRITE( out, "( ' * ', I7, 3ES12.4, 2L10 )" ) i, C_l( i ), C_u( i ),    &
          Y( i ), EQUATION( i ), LINEAR( i )
      END DO
      END SUBROUTINE WRITE_Y

      SUBROUTINE WRITE_X_type( out, n, X_type )
      INTEGER :: n, out
      INTEGER, DIMENSION( n ) :: X_type
      INTEGER :: i
      WRITE( out, "( ' *       i  X_type' )" )
      DO i = 1, n
        WRITE( out, "( ' * ', I7, 2X, I0 )" ) i, X_type( i )
      END DO
      END SUBROUTINE WRITE_X_type

      SUBROUTINE WRITE_p_name( out, p_name )
      INTEGER :: out
      CHARACTER ( len = 10 ) ::  p_name
      WRITE( out, "( ' * p_name = ', A )" ) p_name
      END SUBROUTINE WRITE_p_name

      SUBROUTINE WRITE_X_names( out, n, X_names )
      INTEGER :: n, out
      CHARACTER ( len = 10 ), DIMENSION( n ) :: X_names
      INTEGER :: i
      WRITE( out, "( ' *       i  X_name' )" )
      DO i = 1, n
        WRITE( out, "( ' * ', I7, 2X, A10 )" ) i, X_names( i )
      END DO
      END SUBROUTINE WRITE_X_names

      SUBROUTINE WRITE_C_names( out, m, C_names )
      INTEGER :: m, out
      CHARACTER ( len = 10 ), DIMENSION( m ) :: C_names
      INTEGER :: i
      WRITE( out, "( ' *       i  C_name' )" )
      DO i = 1, m
        WRITE( out, "( ' * ', I7, 2X, A10 )" ) i, C_names( i )
      END DO
      END SUBROUTINE WRITE_C_names

      SUBROUTINE WRITE_f( out, f )
      INTEGER :: out
      REAL ( KIND = wp ) :: f
      WRITE( out, "( ' * f = ', ES12.4 )" ) f
      END SUBROUTINE WRITE_f

      SUBROUTINE WRITE_C( out, m, C )
      INTEGER :: m, out
      REAL ( KIND = wp ), DIMENSION( m ) :: C
      INTEGER :: i
      WRITE( out, "( ' *       i       C' )" )
      DO i = 1, m
        WRITE( out, "( ' * ', I7, ES12.4 )" ) i, C( i )
      END DO
      END SUBROUTINE WRITE_C

      SUBROUTINE WRITE_CI( out, icon, ci )
      INTEGER :: icon, out
      REAL ( KIND = wp ) :: ci
      WRITE( out, "( ' * c(', I0, ') = ', ES12.4 )" ) icon, ci
      END SUBROUTINE WRITE_CI

      SUBROUTINE WRITE_G( out, n, G )
      INTEGER :: n, out
      REAL ( KIND = wp ), DIMENSION( n ) :: G
      INTEGER :: i
      WRITE( out, "( ' *       i       G' )" )
      DO i = 1, n
        WRITE( out, "( ' * ', I7, ES12.4 )" ) i, G( i )
      END DO
      END SUBROUTINE WRITE_G

      SUBROUTINE WRITE_JI( out, n, icon, Ji )
      INTEGER :: n, icon, out
      REAL ( KIND = wp ), DIMENSION( n ) :: Ji
      INTEGER :: i
      WRITE( out, "( ' *       i   J(', I0, ')' )" ) icon
      DO i = 1, n
        WRITE( out, "( ' * ', I7, ES12.4 )" ) i, Ji( i )
      END DO
      END SUBROUTINE WRITE_JI

      SUBROUTINE WRITE_SJI( out, icon, Ji_ne, lji, Ji, J_var )
      INTEGER :: icon, Ji_ne, lji, out
      INTEGER, DIMENSION( lji ) :: J_var
      REAL ( KIND = wp ), DIMENSION( lji ) :: Ji
      INTEGER :: i
      WRITE( out, "( ' *       i   J(', I0, ')' )" ) icon
      DO i = 1, Ji_ne
        WRITE( out, "( ' * ', I7, ES12.4 )" ) J_var( i ), Ji( i )
      END DO
      END SUBROUTINE WRITE_SJI

      SUBROUTINE WRITE_H_dense( out, n, l_h2_1, H2_val )
      INTEGER :: n, l_h2_1, out
      REAL ( KIND = wp ), DIMENSION( l_h2_1, n ) :: H2_val
      INTEGER :: i, j
      WRITE( out, "( ' * H(dense)' )" )
      DO j = 1, n, 4
        IF ( j + 3 <= n ) THEN
          WRITE( out, "( ' *       i   j', I8, 3I12 )" ) j, j + 1, j + 2, j + 3
        ELSE IF ( j + 2 <= n ) THEN
          WRITE( out, "( ' *       i   j', I8, 2I12 )" ) j, j + 1, j + 2
        ELSE IF ( j + 1 <= n ) THEN
          WRITE( out, "( ' *       i   j', I8, I12 )" ) j, j + 1
        ELSE
          WRITE( out, "( ' *       i   j', I8 )" ) j
        END IF
        DO i = 1, n
          IF ( j + 3 <= n ) THEN
            WRITE( out, "( ' * ', I7,  4X, 4ES12.4 )" )                        &
              i, H2_val( i, j ), H2_val( i, j + 1 ),                           &
              H2_val( i, j + 2 ), H2_val( i, j + 3 )
          ELSE IF ( j + 2 <= n ) THEN
            WRITE( out, "( ' * ',  I7, 4X, 3ES12.4 )" )                        &
              i, H2_val( i, j ), H2_val( i, j + 1 ), H2_val( i, j + 2 )
          ELSE IF ( j + 1 <= n ) THEN
            WRITE( out, "( ' * ',  I7, 4X, 2ES12.4 )" )                        &
              i, H2_val( i, j ), H2_val( i, j + 1 )
          ELSE
            WRITE( out, "( ' * ',  I7, 4X, ES12.4 )" ) i, H2_val( i, j )
          END IF
        END DO
      END DO
      END SUBROUTINE WRITE_H_dense

      SUBROUTINE WRITE_J_dense( out, n, m, l_j2_1, l_j2_2, J2_val )
      INTEGER :: n, m, l_J2_1, out
      REAL ( KIND = wp ), DIMENSION( l_j2_1, l_j2_2 ) :: J2_val
      INTEGER :: i, j
      WRITE( out, "( ' * J(dense)' )" )
      DO j = 1, n, 4
        IF ( j + 3 <= n ) THEN
          WRITE( out, "( ' *       i   j', I8, 3I12 )" ) j, j + 1, j + 2, j + 3
        ELSE IF ( j + 2 <= n ) THEN
          WRITE( out, "( ' *       i   j', I8, 2I12 )" ) j, j + 1, j + 2
        ELSE IF ( j + 1 <= n ) THEN
          WRITE( out, "( ' *       i   j', I8, I12 )" ) j, j + 1
        ELSE
          WRITE( out, "( ' *       i   j', I8 )" ) j
        END IF
        DO i = 1, m
          IF ( j + 3 <= n ) THEN
            WRITE( out, "( ' * ', I7,  4X, 4ES12.4 )" )                        &
              i, J2_val( i, j ), J2_val( i, j + 1 ),                           &
              J2_val( i, j + 2 ), J2_val( i, j + 3 )
          ELSE IF ( j + 2 <= n ) THEN
            WRITE( out, "( ' * ',  I7, 4X, 3ES12.4 )" )                        &
              i, J2_val( i, j ), J2_val( i, j + 1 ), J2_val( i, j + 2 )
          ELSE IF ( j + 1 <= n ) THEN
            WRITE( out, "( ' * ',  I7, 4X, 2ES12.4 )" )                        &
              i, J2_val( i, j ), J2_val( i, j + 1 )
          ELSE
            WRITE( out, "( ' * ',  I7, 4X, ES12.4 )" ) i, J2_val( i, j )
          END IF
        END DO
      END DO
      END SUBROUTINE WRITE_J_dense

      SUBROUTINE WRITE_JT_dense( out, n, m, l_j2_1, l_j2_2, J2_val )
      INTEGER :: n, m, l_J2_1, out
      REAL ( KIND = wp ), DIMENSION( l_j2_1, l_j2_2 ) :: J2_val
      INTEGER :: i, j
      WRITE( out, "( ' * J(transpose)(dense)' )" )
      DO j = 1, m, 4
        IF ( j + 3 <= m ) THEN
          WRITE( out, "( ' *       i   j', I8, 3I12 )" ) j, j + 1, j + 2, j + 3
        ELSE IF ( j + 2 <= m ) THEN
          WRITE( out, "( ' *       i   j', I8, 2I12 )" ) j, j + 1, j + 2
        ELSE IF ( j + 1 <= m ) THEN
          WRITE( out, "( ' *       i   j', I8, I12 )" ) j, j + 1
        ELSE
          WRITE( out, "( ' *       i   j', I8 )" ) j
        END IF
        DO i = 1, n
          IF ( j + 3 <= m ) THEN
            WRITE( out, "( ' * ', I7,  4X, 4ES12.4 )" )                        &
              i, J2_val( i, j ), J2_val( i, j + 1 ),                           &
              J2_val( i, j + 2 ), J2_val( i, j + 3 )
          ELSE IF ( j + 2 <= m ) THEN
            WRITE( out, "( ' * ',  I7, 4X, 3ES12.4 )" )                        &
              i, J2_val( i, j ), J2_val( i, j + 1 ), J2_val( i, j + 2 )
          ELSE IF ( j + 1 <= m ) THEN
            WRITE( out, "( ' * ',  I7, 4X, 2ES12.4 )" )                        &
              i, J2_val( i, j ), J2_val( i, j + 1 )
          ELSE
            WRITE( out, "( ' * ',  I7, 4X, ES12.4 )" ) i, J2_val( i, j )
          END IF
        END DO
      END DO
      END SUBROUTINE WRITE_JT_dense

      SUBROUTINE WRITE_H_sparse( out, H_ne, l_h, H_val, H_row, H_col )
      INTEGER :: l_h, H_ne, out
      INTEGER, DIMENSION( l_h ) :: H_row, H_col
      REAL ( KIND = wp ), DIMENSION( l_h ) :: H_val
      INTEGER :: i
      WRITE( out, "( ' * H(sparse)' )" )
      WRITE( out, "( ' * ', 2( '    row    col     val    ' ) )" )
      DO i = 1, H_ne, 2
        IF ( i + 1 <= H_ne ) THEN
          WRITE( out, "( ' * ',  2( 2I7, ES12.4 ) )" )                         &
            H_row( i ), H_col( i ), H_val( i ),                                &
            H_row( i + 1 ), H_col( i + 1 ), H_val( i + 1 )
        ELSE
          WRITE( out, "( ' * ',  2( 2I7, ES12.4 ) )" )                         &
            H_row( i ), H_col( i ), H_val( i )
        END IF
      END DO
      END SUBROUTINE WRITE_H_sparse

      SUBROUTINE WRITE_J_sparse( out, J_ne, l_j, J_val, J_fun, J_var )
      INTEGER :: l_j, J_ne, out
      INTEGER, DIMENSION( l_j ) :: J_fun, J_var
      REAL ( KIND = wp ), DIMENSION( l_j ) :: J_val
      INTEGER :: i
      WRITE( out, "( ' * J(sparse)' )" )
      WRITE( out, "( ' * ', 2( '    fun    var     val    ' ) )" )
      DO i = 1, J_ne, 2
        IF ( i + 1 <= J_ne ) THEN
          WRITE( out, "( ' * ',  2( 2I7, ES12.4 ) )" )                         &
            J_fun( i ), J_var( i ), J_val( i ),                                &
            J_fun( i + 1 ), J_var( i + 1 ), J_val( i + 1 )
        ELSE
          WRITE( out, "( ' * ',  2( 2I7, ES12.4 ) )" )                         &
            J_fun( i ), J_var( i ), J_val( i )
        END IF
      END DO
      END SUBROUTINE WRITE_J_sparse

      SUBROUTINE WRITE_H_element( out, ne, lhe_ptr, HE_row_ptr,                &
                      HE_val_ptr, lhe_row, HE_row, lhe_val, HE_val )
      INTEGER :: ne, lhe_ptr, lhe_row, lhe_val, out
      INTEGER, DIMENSION( lhe_ptr ) :: HE_row_ptr, HE_val_ptr
      INTEGER, DIMENSION( lhe_row ) :: HE_row
      REAL ( KIND = wp ), DIMENSION( lhe_val ) :: HE_val
      WRITE( out, "( ' * H(element)' )" )
      DO i = 1, ne
        IF (  HE_row_ptr( i + 1 ) > HE_row_ptr( i ) ) THEN
          WRITE( out, "( ' * element ', I0 )" ) i
          WRITE( out, "( ' * indices ', 5I12, /, ( ' *', 9X, 5I12 ) )" )       &
           HE_row( HE_row_ptr( i ) : HE_row_ptr( i + 1 ) - 1 )
          WRITE( out, "( ' * values  ', 5ES12.4, /, ( ' *', 9X, 5ES12.4 ) )" ) &
           HE_val( HE_val_ptr( i ) : HE_val_ptr( i + 1 ) - 1 )
        ELSE
          WRITE( out, "( ' * no indices' )" )
        END IF
      END DO
      END SUBROUTINE WRITE_H_element

      SUBROUTINE WRITE_RESULT( out, n, VECTOR, RESULT )
      INTEGER :: n, out
      REAL ( KIND = wp ), DIMENSION( n ) :: VECTOR, RESULT
      INTEGER :: i
      WRITE( out, "( ' *       i    VECTOR     RESULT' )" )
      DO i = 1, n
        WRITE( out, "( ' * ', I7, 2ES12.4 )" ) i, VECTOR( i ), RESULT( i )
      END DO
      END SUBROUTINE WRITE_RESULT

    END PROGRAM CUTEST_test_constrained_tools