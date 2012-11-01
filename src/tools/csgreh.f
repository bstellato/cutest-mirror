! ( Last modified on 23 Dec 2000 at 22:01:38 )
      SUBROUTINE CSGREH( N, M, X, GRLAGF, LV, V,  &
                         NNZJ, LCJAC, CJAC, INDVAR, INDFUN,  &
                         NE, IRNHI, LIRNHI, LE, &
                         IPRNHI, HI, LHI, IPRHI, BYROWS )
      INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )
      INTEGER :: N, M, LV, NNZJ, LCJAC 
      INTEGER :: NE, LE, LIRNHI, LHI 
      LOGICAL :: GRLAGF, BYROWS
      INTEGER :: INDVAR( LCJAC), INDFUN( LCJAC )
      INTEGER :: IRNHI ( LIRNHI )
      INTEGER :: IPRNHI( LE ), IPRHI ( LE )
      REAL ( KIND = wp ) :: X ( N ), V ( LV ),  &
                         HI ( LHI ), CJAC ( LCJAC )

!  Compute the Jacobian matrix for an optimization problem
!  initially written in Standard Input Format (SIF).
!  Also compute the Hessian matrix of the Lagrangian function of
!  the problem.

!  The Jacobian is represented in "co-ordinate" format.
!  The Hessian is represented in "finite element format", i.e., 

!           ne
!      H = sum H_i, 
!          i=1

!  where each element H_i involves a small subset of the rows of H.
!  H is stored as a list of the row indices involved in each element
!  and the upper triangle of H_i (stored by rows or columns). 
!  Specifically,

!  NE (integer) number of elements
!  IRNHI (integer array) a list of the row indices involved which each
!          element. Those for element i directly proceed those for 
!          element i + 1, i = 1, ..., NE-1
!  IPRNHI (integer array) pointers to the position in IRNHI of the first 
!          row index in each element. IPRNHI(NE + 1) points to the first 
!          empty location in IRPNHI
!  HI (real array) a list of the nonzeros in the upper triangle of
!          H_i, stored by rows, or by columns, for each element. Those 
!          for element i directly proceed those for element, i + 1, 
!          i = 1, ..., NE-1
!  IPRHI (integer array) pointers to the position in HI of the first 
!          nonzero in each element. IPRHI(NE + 1) points to the first 
!          empty location in HI
!  BYROWS (logical) must be set .TRUE. if the upper triangle of each H_i 
!          is to be stored by rows, and .FALSE. if it is to be stored
!          by columns.

!  Based on the minimization subroutine LANCELOT/SBMIN
!  by Conn, Gould and Toint.

!  Nick Gould, for CGT productions,
!  November 1994.

      INTEGER :: LIWK, LWK, LFUVAL, LLOGIC, LCHARA

! ---------------------------------------------------------------------

!  Parameters whose value might be changed by the user:

!  The following parameters define the sizes of problem
!  dependent arrays. These may be changed by the user to
!  suit a particular problem or system configuration.

!  The TOOLS will issue error messages if any of these sizes
!  is too small, telling which parameter to increase.

! ---------------------------------------------------------------------

      INCLUDE 'tools.siz'

      INTEGER :: IWK( LIWK )
      LOGICAL :: LOGI ( LLOGIC )
      CHARACTER ( LEN = 10 ) :: CHA ( LCHARA )
      REAL ( KIND = wp ) :: WK ( LWK )
      REAL ( KIND = wp ) :: FUVALS ( LFUVAL )

! ---------------------------------------------------------------------

!  End of parameters which might be changed by the user.

! ---------------------------------------------------------------------

!  integer variables from the GLOBAL common block.

      INTEGER :: NG, NELNUM, NGEL, NVARS, NNZA, NGPVLU
      INTEGER :: NEPVLU, NG1, NEL1, ISTADG, ISTGP, ISTADA
      INTEGER :: ISTAEV, ISTEP, ITYPEG, KNDOFC, ITYPEE
      INTEGER :: IELING, IELVAR, ICNA, ISTADH, INTVAR, IVAR
      INTEGER :: ICALCF, ITYPEV, IWRK, A, B
      INTEGER :: U, GPVALU, EPVALU
      INTEGER :: ESCALE, GSCALE, VSCALE, GVALS, XT, DGRAD
      INTEGER :: Q, WRK, INTREP, GXEQX, GNAMES, VNAMES
      INTEGER :: LO, CH, LIWORK, LWORK, NGNG, FT
      INTEGER :: LA, LB, NOBJGR, LU, LELVAR
      INTEGER :: LSTAEV, LSTADH, LNTVAR, LCALCF
      INTEGER :: LELING, LINTRE, LFT, LGXEQX, LSTADG, LGVALS
      INTEGER :: LICNA, LSTADA, LKNDOF, LGPVLU, LEPVLU
      INTEGER :: LGSCAL, LESCAL, LVSCAL, LCALCG

!  integer variables from the LOCAL common block.

      INTEGER :: LFXI, LGXI, LHXI, LGGFX, LDX, LGRJAC
      INTEGER :: LQGRAD, LBREAK, LP, LXCP, LX0, LGX0
      INTEGER :: LDELTX, LBND, LWKSTR, LSPTRS, LSELTS, LINDEX
      INTEGER :: LSWKSP, LSTAGV, LSTAJC, LIUSED, LFREEC
      INTEGER :: LNNONZ, LNONZ2, LSYMMD, LSYMMH
      INTEGER :: LSLGRP, LSVGRP, LGCOLJ, LVALJR, LSEND
      INTEGER :: LNPTRS, LNELTS, LNNDEX, LNWKSP, LNSTGV
      INTEGER :: LNSTJC, LNIUSE, LNFREC, LNNNON, LNNNO2, LNSYMD
      INTEGER :: LNSYMH, LNLGRP, LNVGRP, LNGCLJ, LNVLJR, LNQGRD
      INTEGER :: LNBRAK, LNP, LNBND, LNFXI, LNGXI, LNGUVL
      INTEGER :: LNHXI, LNHUVL, LNGGFX, LNDX, LNGRJC, LIWK2
      INTEGER :: LWK2, MAXSIN, NINVAR, MAXSEL
      INTEGER :: NTYPE, NSETS, LSTYPE, LSSWTR, LSSIWT, LSIWTR
      INTEGER :: LSWTRA, LNTYPE, LNSWTR, LNSIWT, LNIWTR
      INTEGER :: LNWTRA, LSISET, LSSVSE, LNISET, LNSVSE
      LOGICAL :: ALTRIV, FIRSTG

!  integer variables from the PRFCTS common block.

      INTEGER :: NC2OF, NC2OG, NC2OH, NC2CF, NC2CG, NC2CH
      INTEGER :: NHVPR, PNC
      REAL :: SUTIME, STTIME
      COMMON / GLOBAL /  IWK, WK, FUVALS, LOGI, &
                         NG, NELNUM, NGEL, NVARS, NNZA, NGPVLU, &
                         NEPVLU, NG1, NEL1, ISTADG, ISTGP, ISTADA, &
                         ISTAEV, ISTEP, ITYPEG, KNDOFC, ITYPEE, &
                         IELING, IELVAR, ICNA, ISTADH, INTVAR, IVAR, &
                         ICALCF, ITYPEV, IWRK, A, B, &
                         U, GPVALU, EPVALU, &
                         ESCALE, GSCALE, VSCALE, GVALS, XT, DGRAD, &
                         Q, WRK, INTREP, GXEQX, GNAMES, VNAMES, &
                         LO, CH, LIWORK, LWORK, NGNG, FT, &
                         ALTRIV, FIRSTG, &
                         LA, LB, NOBJGR, LU, LELVAR, &
                         LSTAEV, LSTADH, LNTVAR, LCALCF, &
                         LELING, LINTRE, LFT, LGXEQX, LSTADG, LGVALS, &
                         LICNA, LSTADA, LKNDOF, LGPVLU, LEPVLU, &
                         LGSCAL, LESCAL, LVSCAL, LCALCG
      COMMON / CHARA /   CHA
      COMMON / LOCAL /   LFXI, LGXI, LHXI, LGGFX, LDX, LGRJAC, &
                         LQGRAD, LBREAK, LP, LXCP, LX0, LGX0, &
                         LDELTX, LBND, LWKSTR, LSPTRS, LSELTS, LINDEX, &
                         LSWKSP, LSTAGV, LSTAJC, LIUSED, LFREEC, &
                         LNNONZ, LNONZ2, LSYMMD, LSYMMH, &
                         LSLGRP, LSVGRP, LGCOLJ, LVALJR, LSEND, &
                         LNPTRS, LNELTS, LNNDEX, LNWKSP, LNSTGV, &
                         LNSTJC, LNIUSE, LNFREC, LNNNON, LNNNO2, LNSYMD, &
                         LNSYMH, LNLGRP, LNVGRP, LNGCLJ, LNVLJR, LNQGRD, &
                         LNBRAK, LNP, LNBND, LNFXI, LNGXI, LNGUVL, &
                         LNHXI, LNHUVL, LNGGFX, LNDX, LNGRJC, LIWK2, &
                         LWK2, MAXSIN, NINVAR, MAXSEL, NTYPE, &
                         NSETS, LSTYPE, LSSWTR, LSSIWT, LSIWTR, &
                         LSWTRA, LNTYPE, LNSWTR, LNSIWT, LNIWTR, &
                         LNWTRA, LSISET, LSSVSE, LNISET, LNSVSE
      COMMON / PRFCTS /  NC2OF, NC2OG, NC2OH, NC2CF, NC2CG, NC2CH, &
                         NHVPR, PNC, SUTIME, STTIME
      INTEGER :: IOUT
      COMMON / OUTPUT /  IOUT
      INTEGER :: NUMVAR, NUMCON
      COMMON / DIMS /    NUMVAR, NUMCON
      SAVE             / GLOBAL /, / LOCAL /, / CHARA /, / OUTPUT /, &
                       / DIMS   /, / PRFCTS /

!  Local variables

      INTEGER :: I, J, IEL, K, IG, II, IG1, L, JJ, LL
      INTEGER :: LIWKH, ICON, LGTEMP, INFORM, IENDGV
      INTEGER :: NIN, NVAREL, NELOW, NELUP, ISTRGV
      INTEGER :: IFSTAT, IGSTAT
      LOGICAL :: NONTRV
      REAL ( KIND = wp ) :: FTT, ONE, ZERO, GI, SCALEE, GII
      PARAMETER ( ZERO = 0.0_wp, ONE = 1.0_wp )
      EXTERNAL :: RANGE, ELFUN, GROUP 
!D    EXTERNAL           DSETVL, DSETVI, DELGRD, DASMBE

!  there are non-trivial group functions.

      DO 10 I = 1, MAX( NELNUM, NG )
        IWK( ICALCF + I ) = I
   10 CONTINUE

!  evaluate the element function values.

      CALL ELFUN ( FUVALS, X, WK( EPVALU + 1 ), NELNUM, &
                   IWK( ITYPEE + 1 ), IWK( ISTAEV + 1 ), &
                   IWK( IELVAR + 1 ), IWK( INTVAR + 1 ), &
                   IWK( ISTADH + 1 ), IWK( ISTEP + 1 ), &
                   IWK( ICALCF + 1 ),  &
                   LINTRE, LSTAEV, LELVAR, LNTVAR, LSTADH,  &
                   LNTVAR, LINTRE, LFUVAL, LVSCAL, LEPVLU,  &
                   1, IFSTAT )

!  evaluate the element function gradients and Hessians.

      CALL ELFUN ( FUVALS, X, WK( EPVALU + 1 ), NELNUM, &
                   IWK( ITYPEE + 1 ), IWK( ISTAEV + 1 ), &
                   IWK( IELVAR + 1 ), IWK( INTVAR + 1 ), &
                   IWK( ISTADH + 1 ), IWK( ISTEP + 1 ), &
                   IWK( ICALCF + 1 ),  &
                   LINTRE, LSTAEV, LELVAR, LNTVAR, LSTADH,  &
                   LNTVAR, LINTRE, LFUVAL, LVSCAL, LEPVLU,  &
                   3, IFSTAT )

!  compute the group argument values ft.

      DO 70 IG = 1, NG
         FTT = - WK( B + IG )

!  include the contribution from the linear element.

         DO 30 J = IWK( ISTADA + IG ), IWK( ISTADA + IG + 1 ) - 1
            FTT = FTT + WK( A + J ) * X( IWK( ICNA + J ) )
   30    CONTINUE

!  include the contributions from the nonlinear elements.

         DO 60 J = IWK( ISTADG + IG ), IWK( ISTADG + IG + 1 ) - 1
            FTT = FTT + WK( ESCALE + J ) * FUVALS( IWK( IELING + J ) )
   60    CONTINUE
         WK( FT + IG ) = FTT

!  Record the derivatives of trivial groups.

         IF ( LOGI( GXEQX + IG ) ) THEN
            WK( GVALS + NG + IG ) = ONE
            WK( GVALS + 2 * NG + IG ) = ZERO
         END IF
   70 CONTINUE

!  evaluate the group derivative values.

      IF ( .NOT. ALTRIV ) CALL GROUP ( WK ( GVALS + 1 ), NG, &
            WK( FT + 1 ), WK ( GPVALU + 1 ), NG, &
            IWK( ITYPEG + 1 ), IWK( ISTGP + 1 ), &
            IWK( ICALCF + 1 ), &
            LCALCG, NG1, LCALCG, LCALCG, LGPVLU, &
            .TRUE., IGSTAT )

!  Define the real work space needed for ELGRD.
!  Ensure that there is sufficient space.

      IF ( LWK2 < NG ) THEN
         IF ( IOUT > 0 ) WRITE( IOUT, 2000 )
         STOP
      END IF
      IF ( NUMCON > 0 ) THEN

!  Change the group weightings to include the contributions from
!  the Lagrange multipliers.

         DO 80 IG = 1, NG
            I = IWK( KNDOFC + IG )
            IF ( I == 0 ) THEN
               WK( LWKSTR + IG ) = WK( GSCALE + IG )
            ELSE
               WK( LWKSTR + IG ) = WK( GSCALE + IG ) * V( I )
            END IF
   80    CONTINUE

!  Compute the gradient values. Initialize the gradient of the
!  objective function as zero.

         NNZJ = 0
         LGTEMP = WRK + N + MAXSEL
         DO 120 J = 1, N
            WK( LGTEMP + J ) = ZERO
  120    CONTINUE

!  Consider the IG-th group.

         DO 290 IG = 1, NG
            IG1 = IG + 1
            ICON = IWK( KNDOFC + IG )
            ISTRGV = IWK( LSTAGV + IG )
            IENDGV = IWK( LSTAGV + IG1 ) - 1
            NELOW = IWK( ISTADG + IG )
            NELUP = IWK( ISTADG + IG1 ) - 1
            NONTRV = .NOT. LOGI( GXEQX + IG )

!  Compute the first derivative of the group.

            GI = WK( GSCALE + IG )
            GII = WK( LWKSTR + IG )
            IF ( NONTRV ) THEN
               GI = GI  * WK( GVALS + NG + IG )
               GII = GII * WK( GVALS + NG + IG )
            END IF
      CALL DSETVI( IENDGV - ISTRGV + 1, WK( WRK + 1 ), &
                         IWK( LSVGRP + ISTRGV ), ZERO )

!  This is the first gradient evaluation or the group has nonlinear
!  elements.

            IF ( FIRSTG .OR. NELOW <= NELUP ) THEN

!  Loop over the group's nonlinear elements.

               DO 150 II = NELOW, NELUP
                  IEL = IWK( IELING + II )
                  K = IWK( INTVAR + IEL )
                  L = IWK( ISTAEV + IEL )
                  NVAREL = IWK( ISTAEV + IEL + 1 ) - L
                  SCALEE = WK( ESCALE + II )
                  IF ( LOGI( INTREP + IEL ) ) THEN

!  The IEL-th element has an internal representation.

                     NIN = IWK( INTVAR + IEL + 1 ) - K
                     CALL RANGE ( IEL, .TRUE., FUVALS( K ), &
                                  WK( WRK + N + 1 ), NVAREL, NIN, &
                                  IWK( ITYPEE + IEL ), &
                                  NIN, NVAREL )
!DIR$ IVDEP
                     DO 130 I = 1, NVAREL
                        J = IWK( IELVAR + L )
                        WK( WRK + J ) = WK( WRK + J ) + &
                                           SCALEE * WK( WRK + N + I )
                        L = L + 1
  130                CONTINUE
                  ELSE

!  The IEL-th element has no internal representation.

!DIR$ IVDEP
                     DO 140 I = 1, NVAREL
                        J = IWK( IELVAR + L )
                        WK( WRK + J ) = WK( WRK + J ) + &
                                           SCALEE * FUVALS( K )
                        K = K + 1
                        L = L + 1
  140                CONTINUE
                  END IF
  150          CONTINUE

!  Include the contribution from the linear element.

!DIR$ IVDEP
               DO 160 K = IWK( ISTADA + IG ), &
                                  IWK( ISTADA + IG1 ) - 1
                  J = IWK( ICNA + K )
                  WK( WRK + J ) = WK( WRK + J ) + WK( A + K )
  160          CONTINUE

!  Allocate a gradient.

!DIR$ IVDEP
               DO 190 I = ISTRGV, IENDGV
                  LL = IWK( LSVGRP + I )

!  The group belongs to the objective function.

                  IF ( ICON == 0 ) THEN
                     WK( LGTEMP + LL ) = WK( LGTEMP + LL ) + &
                                         GI * WK( WRK + LL )

!  The group defines a constraint.

                  ELSE
                     NNZJ = NNZJ + 1
                     IF ( NNZJ <= LCJAC ) THEN
                        CJAC ( NNZJ ) = GI * WK( WRK + LL )
                        INDFUN( NNZJ ) = ICON
                        INDVAR( NNZJ ) = LL
                     END IF
                     IF ( GRLAGF ) &
                        WK( LGTEMP + LL ) = WK( LGTEMP + LL ) + &
                                            GII * WK( WRK + LL )
                  END IF

!  If the group is non-trivial, also store the nonzero entries of the
!  gradient of the function in GRJAC.

                  IF ( NONTRV ) THEN
                     JJ = IWK( LSTAJC + LL )
                     FUVALS( LGRJAC + JJ ) = WK ( WRK + LL )

!  Increment the address for the next nonzero in the column of
!  the jacobian for variable LL.

                     IWK( LSTAJC + LL ) = JJ + 1
                  END IF
  190          CONTINUE

!  This is not the first gradient evaluation and there is only a linear
!  element.

            ELSE
!                            linear element improved. 43 lines replace 40

!  Include the contribution from the linear element.

!DIR$ IVDEP
               DO 210 K = IWK( ISTADA + IG ),IWK( ISTADA + IG1 ) - 1
                  J = IWK( ICNA + K )
                  WK( WRK + J ) = WK( WRK + J ) + WK( A + K )
  210          CONTINUE

!  Allocate a gradient.

!DIR$ IVDEP
               DO 220 I = ISTRGV, IENDGV
                  LL = IWK( LSVGRP + I )

!  The group belongs to the objective function.

                  IF ( ICON == 0 ) THEN
                     WK( LGTEMP + LL ) = WK( LGTEMP + LL ) + &
                                         GI * WK( WRK + LL )

!  The group defines a constraint.

                  ELSE
                     NNZJ = NNZJ + 1
                     IF ( NNZJ <= LCJAC ) THEN
                        CJAC ( NNZJ ) = GI * WK( WRK + LL )
                        INDFUN( NNZJ ) = ICON
                        INDVAR( NNZJ ) = LL
                     END IF
                     IF ( GRLAGF ) &
                        WK( LGTEMP + LL ) = WK( LGTEMP + LL ) + &
                                            GII * WK( WRK + LL )
                  END IF

!  Increment the address for the next nonzero in the column of
!  the jacobian for variable LL.

                  IF ( NONTRV ) THEN
                     JJ = IWK( LSTAJC + LL )
                     IWK( LSTAJC + LL ) = JJ + 1
                  END IF
  220          CONTINUE
            END IF
  290    CONTINUE

!  Reset the starting addresses for the lists of groups using
!  each variable to their values on entry.

         DO 300 I = N, 2, - 1
            IWK( LSTAJC + I ) = IWK( LSTAJC + I - 1 )
  300    CONTINUE
         IWK( LSTAJC + 1 ) = 1

!  Transfer the gradient of the objective function to the sparse
!  storage scheme.

         DO 310 I = 1, N
!           IF ( WK( LGTEMP + I ) /= ZERO ) THEN
               NNZJ = NNZJ + 1
               IF ( NNZJ <= LCJAC ) THEN
                  CJAC ( NNZJ ) = WK( LGTEMP + I )
                  INDFUN( NNZJ ) = 0
                  INDVAR( NNZJ ) = I
               END IF
!           END IF
  310    CONTINUE
      ELSE

!  Compute the gradient value.

      CALL DELGRD( N, NG, FIRSTG, IWK( ICNA + 1 ), LICNA, &
                      IWK( ISTADA + 1 ), LSTADA, IWK( IELING + 1 ), &
                      LELING, IWK( ISTADG + 1 ), LSTADG, &
                      IWK( ITYPEE + 1 ), LINTRE, &
                      IWK( ISTAEV + 1 ), LSTAEV, IWK( IELVAR + 1 ), &
                      LELVAR, IWK( INTVAR + 1 ), LNTVAR, &
                      IWK( LSVGRP + 1 ), &
                      LNVGRP, IWK( LSTAJC + 1 ), LNSTJC, &
                      IWK( LSTAGV + 1 ), LNSTGV, WK( A + 1 ), LA, &
                      WK( GVALS + NG + 1 ), LGVALS, &
                      FUVALS, LNGUVL, FUVALS( LGGFX + 1 ), &
                      WK( GSCALE + 1 ), LGSCAL, &
                      WK( ESCALE + 1 ), LESCAL, FUVALS( LGRJAC + 1 ), &
                      LNGRJC, WK( WRK + 1 ), WK( WRK + N + 1 ), MAXSEL, &
                      LOGI( GXEQX + 1 ), LGXEQX, &
                      LOGI( INTREP + 1 ), LINTRE, RANGE )

!  Transfer the gradient of the objective function to the sparse
!  storage scheme.

         NNZJ = 0
         DO 400 I = 1, N
!           IF ( FUVALS( LGGFX + I ) /= ZERO ) THEN
               NNZJ = NNZJ + 1
               IF ( NNZJ <= LCJAC ) THEN
                  CJAC ( NNZJ ) = FUVALS( LGGFX + I )
                  INDFUN( NNZJ ) = 0
                  INDVAR( NNZJ ) = I
               END IF
!           END IF
  400    CONTINUE
      END IF
      FIRSTG = .FALSE.

!  Verify that the Jacobian can fit in the alloted space

      IF ( NNZJ > LCJAC ) THEN
         IF ( IOUT > 0 ) WRITE( IOUT, 2030 ) NNZJ - LCJAC 
         STOP
      END IF

!  Define the real work space needed for ASMBE.
!  Ensure that there is sufficient space.

      IF ( NUMCON > 0 ) THEN
         IF ( LWK2 < N + 3 * MAXSEL + NG ) THEN
            IF ( IOUT > 0 ) WRITE( IOUT, 2000 )
            STOP
         END IF
      ELSE
         IF ( LWK2 < N + 3 * MAXSEL ) THEN
            IF ( IOUT > 0 ) WRITE( IOUT, 2000 )
            STOP
         END IF
      END IF

!  Define the integer work space needed for ASMBE.
!  Ensure that there is sufficient space.

      LIWKH = LIWK2 - N

!  Assemble the Hessian.

      IF ( NUMCON > 0 ) THEN
      CALL DASMBE( N, NG, MAXSEL,  &
                      IWK( ISTADH + 1 ), LSTADH, &
                      IWK( ICNA + 1 ), LICNA, &
                      IWK( ISTADA + 1 ), LSTADA, &
                      IWK( INTVAR + 1 ), LNTVAR, &
                      IWK( IELVAR + 1 ), LELVAR, &
                      IWK( IELING + 1 ), LELING, &
                      IWK( ISTADG + 1 ), LSTADG, &
                      IWK( ISTAEV + 1 ), LSTAEV, &
                      IWK( LSTAGV + 1 ), LNSTGV, &
                      IWK( LSVGRP + 1 ), LNVGRP, &
                      IWK( LIWKH + 1 ), LIWK2 - LIWKH, &
                      WK( A + 1 ), LA, FUVALS, LNGUVL, FUVALS, LNHUVL, &
                      WK( GVALS + NG + 1 ), WK( GVALS + 2 * NG + 1 ), &
                      WK( LWKSTR + 1 ), WK( ESCALE + 1 ), LESCAL, &
                      WK ( LWKSTR + NG + 1 ), LWK2 - NG, &
                      LOGI( GXEQX + 1 ), LGXEQX, LOGI( INTREP + 1 ), &
                      LINTRE, IWK( ITYPEE + 1 ), LINTRE, RANGE, NE,  &
                      IRNHI, LIRNHI, IPRNHI, HI, LHI, IPRHI, &
                      BYROWS, 1, IOUT, INFORM )
      ELSE
      CALL DASMBE( N, NG, MAXSEL,  &
                      IWK( ISTADH + 1 ), LSTADH, &
                      IWK( ICNA + 1 ), LICNA, &
                      IWK( ISTADA + 1 ), LSTADA, &
                      IWK( INTVAR + 1 ), LNTVAR, &
                      IWK( IELVAR + 1 ), LELVAR, &
                      IWK( IELING + 1 ), LELING, &
                      IWK( ISTADG + 1 ), LSTADG, &
                      IWK( ISTAEV + 1 ), LSTAEV, &
                      IWK( LSTAGV + 1 ), LNSTGV, &
                      IWK( LSVGRP + 1 ), LNVGRP, &
                      IWK( LIWKH + 1 ), LIWK2 - LIWKH, &
                      WK( A + 1 ), LA, FUVALS, LNGUVL, FUVALS, LNHUVL, &
                      WK( GVALS + NG + 1 ), WK( GVALS + 2 * NG + 1 ), &
                      WK( GSCALE + 1 ), WK( ESCALE + 1 ), LESCAL, &
                      WK ( LWKSTR + 1 ), LWK2 - NG, &
                      LOGI( GXEQX + 1 ), LGXEQX, LOGI( INTREP + 1 ), &
                      LINTRE, IWK( ITYPEE + 1 ), LINTRE, RANGE, NE,  &
                      IRNHI, LIRNHI, IPRNHI, HI, LHI, IPRHI, &
                      BYROWS, 1, IOUT, INFORM )
      END IF

!  Check that there is room for the elements

      IF ( INFORM > 0 ) THEN
         IF ( IOUT > 0 ) WRITE( IOUT, 2020 )
         STOP
      END IF

!  Update the counters for the report tool.

      NC2CG = NC2OG + 1
      NC2OH = NC2OH + 1
      NC2CG = NC2CG + PNC
      NC2CH = NC2CH + PNC
      RETURN

! Non-executable statements.

 2000 FORMAT( ' ** SUBROUTINE CSGREH: Increase the size of WK ' )
 2020 FORMAT( ' ** SUBROUTINE CSGREH: Increase the size of', &
              ' IPNRHI, IPRHI, IRNHI or HI ' )
 2030 FORMAT( /, ' ** SUBROUTINE CSGREH: array length LCJAC too small.', &
              /, ' -- Minimization abandoned.', &
              /, ' -- Increase the parameter LCJAC by at least ', I8, &
                 ' and restart.' )

!  end of CSGREH.

      END
