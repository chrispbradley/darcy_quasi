PROGRAM darcy_quasistatic

  USE OpenCMISS
  USE OpenCMISS_Iron

#ifndef NOMPIMOD
  USE MPI
#endif
  IMPLICIT NONE
#ifdef NOMPIMOD
#include "mpif.h"
#endif

  !
  !================================================================================================================================
  !

  !Test program parameters

  REAL(CMISSRP), PARAMETER :: HEIGHT=1.0_CMISSRP
  REAL(CMISSRP), PARAMETER :: WIDTH=1.0_CMISSRP
  REAL(CMISSRP), PARAMETER :: LENGTH=1.0_CMISSRP
  INTEGER(CMISSIntg), PARAMETER :: CoordinateSystemUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: RegionUserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: MeshUserNumber=3
  INTEGER(CMISSIntg), PARAMETER :: DecompositionUserNumber=4
  INTEGER(CMISSIntg), PARAMETER :: GeometricFieldUserNumber=5
  INTEGER(CMISSIntg), PARAMETER :: DependentFieldUserNumberDarcy=6
  INTEGER(CMISSIntg), PARAMETER :: DependentFieldUserNumberMatProperties=42
  INTEGER(CMISSIntg), PARAMETER :: MaterialsFieldUserNumberDarcy=8
  INTEGER(CMISSIntg), PARAMETER :: MaterialsFieldUserNumberMatProperties=9
  !   INTEGER(CMISSIntg), PARAMETER :: IndependentFieldUserNumberDarcy=10
  !   INTEGER(CMISSIntg), PARAMETER :: IndependentFieldUserNumberMatProperties=11
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetUserNumberDarcy=12
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetUserNumberMatProperties=13
  INTEGER(CMISSIntg), PARAMETER :: ProblemUserNumber=14
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetFieldUserNumberDarcy=21
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetFieldUserNumberMatProperties=22
  INTEGER(CMISSIntg), PARAMETER :: GeneratedMeshUserNumber=15

  INTEGER(CMISSIntg), PARAMETER :: SolverMatPropertiesUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: SolverDarcyUserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: MaterialsFieldUserNumberDarcyPorosity=1
  INTEGER(CMISSIntg), PARAMETER :: MaterialsFieldUserNumberDarcyPermOverVis=2
  INTEGER(CMISSIntg), PARAMETER :: MaterialsFieldUserNumberMatPropertiesPorosity=1
  INTEGER(CMISSIntg), PARAMETER :: MaterialsFieldUserNumberMatPropertiesPermOverVis=2

  !Program variables

  INTEGER(CMISSIntg) :: NUMBER_OF_DIMENSIONS
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS
  INTEGER(CMISSIntg) :: BASIS_TYPE
  INTEGER(CMISSIntg) :: BASIS_NUMBER_GEOMETRY
  INTEGER(CMISSIntg) :: BASIS_NUMBER_VELOCITY
  INTEGER(CMISSIntg) :: BASIS_NUMBER_PRESSURE
  INTEGER(CMISSIntg) :: BASIS_XI_GAUSS_GEOMETRY
  INTEGER(CMISSIntg) :: BASIS_XI_GAUSS_VELOCITY
  INTEGER(CMISSIntg) :: BASIS_XI_GAUSS_PRESSURE
  INTEGER(CMISSIntg) :: BASIS_XI_INTERPOLATION_GEOMETRY
  INTEGER(CMISSIntg) :: BASIS_XI_INTERPOLATION_VELOCITY
  INTEGER(CMISSIntg) :: BASIS_XI_INTERPOLATION_PRESSURE
  INTEGER(CMISSIntg) :: MESH_NUMBER_OF_COMPONENTS
  INTEGER(CMISSIntg) :: MESH_COMPONENT_NUMBER_GEOMETRY
  INTEGER(CMISSIntg) :: MESH_COMPONENT_NUMBER_VELOCITY
  INTEGER(CMISSIntg) :: MESH_COMPONENT_NUMBER_PRESSURE
  INTEGER(CMISSIntg) :: NUMBER_OF_COMPONENTS_DEPENDENT_FIELD_MAT_PROPERTIES
  INTEGER(CMISSIntg) :: NUMBER_OF_NODES_GEOMETRY
  INTEGER(CMISSIntg) :: NUMBER_OF_NODES_VELOCITY
  INTEGER(CMISSIntg) :: NUMBER_OF_NODES_PRESSURE
  INTEGER(CMISSIntg) :: NUMBER_OF_ELEMENT_NODES_GEOMETRY
  INTEGER(CMISSIntg) :: NUMBER_OF_ELEMENT_NODES_VELOCITY
  INTEGER(CMISSIntg) :: NUMBER_OF_ELEMENT_NODES_PRESSURE
  INTEGER(CMISSIntg) :: TOTAL_NUMBER_OF_NODES
  INTEGER(CMISSIntg) :: TOTAL_NUMBER_OF_ELEMENTS
  INTEGER(CMISSIntg) :: MAXIMUM_ITERATIONS
  INTEGER(CMISSIntg) :: RESTART_VALUE
  INTEGER(CMISSIntg) :: EQUATIONS_DARCY_OUTPUT
  INTEGER(CMISSIntg) :: EQUATIONS_MAT_PROPERTIES_OUTPUT
  INTEGER(CMISSIntg) :: COMPONENT_NUMBER
  INTEGER(CMISSIntg) :: NODE_NUMBER
  INTEGER(CMISSIntg) :: ELEMENT_NUMBER
  INTEGER(CMISSIntg) :: CONDITION
  INTEGER(CMISSIntg) :: LINEAR_SOLVER_DARCY_OUTPUT_FREQUENCY
  INTEGER(CMISSIntg) :: LINEAR_SOLVER_DARCY_OUTPUT_TYPE
  INTEGER(CMISSIntg) :: LINEAR_SOLVER_MAT_PROPERTIES_OUTPUT_TYPE
  REAL(CMISSRP) :: INITIAL_FIELD_DARCY(3)
  REAL(CMISSRP) :: INITIAL_FIELD_MAT_PROPERTIES(3)
  REAL(CMISSRP) :: DIVERGENCE_TOLERANCE
  REAL(CMISSRP) :: RELATIVE_TOLERANCE
  REAL(CMISSRP) :: ABSOLUTE_TOLERANCE
  REAL(CMISSRP) :: LINESEARCH_ALPHA
  REAL(CMISSRP) :: VALUE
  REAL(CMISSRP) :: POROSITY_PARAM_MAT_PROPERTIES, PERM_OVER_VIS_PARAM_MAT_PROPERTIES
  REAL(CMISSRP) :: POROSITY_PARAM_DARCY, PERM_OVER_VIS_PARAM_DARCY
  REAL(CMISSRP) :: LINEAR_SOLVER_DARCY_START_TIME
  REAL(CMISSRP) :: LINEAR_SOLVER_DARCY_STOP_TIME
  REAL(CMISSRP) :: LINEAR_SOLVER_DARCY_TIME_INCREMENT
  LOGICAL :: EXPORT_FIELD_IO
  LOGICAL :: LINEAR_SOLVER_DARCY_DIRECT_FLAG
  LOGICAL :: LINEAR_SOLVER_MAT_PROPERTIES_DIRECT_FLAG

  !CMISS variables

  TYPE(cmfe_RegionType) :: Region
  TYPE(cmfe_RegionType) :: WorldRegion
  TYPE(cmfe_ComputationEnvironmentType) :: computationEnvironment
  TYPE(cmfe_CoordinateSystemType) :: CoordinateSystem
  TYPE(cmfe_CoordinateSystemType) :: WorldCoordinateSystem
  TYPE(cmfe_BasisType) :: BasisGeometry
  TYPE(cmfe_BasisType) :: BasisVelocity
  TYPE(cmfe_BasisType) :: BasisPressure
  TYPE(cmfe_NodesType) :: Nodes
  TYPE(cmfe_MeshElementsType) :: MeshElementsGeometry
  TYPE(cmfe_MeshElementsType) :: MeshElementsVelocity
  TYPE(cmfe_MeshElementsType) :: MeshElementsPressure
  TYPE(cmfe_MeshType) :: Mesh
  TYPE(cmfe_GeneratedMeshType) :: GeneratedMesh
  TYPE(cmfe_DecompositionType) :: Decomposition
  TYPE(cmfe_FieldsType) :: Fields
  TYPE(cmfe_FieldType) :: GeometricField
  TYPE(cmfe_FieldType) :: DependentFieldDarcy
  TYPE(cmfe_FieldType) :: DependentFieldMatProperties
  TYPE(cmfe_FieldType) :: MaterialsFieldDarcy
  TYPE(cmfe_FieldType) :: MaterialsFieldMatProperties
  TYPE(cmfe_FieldType) :: EquationsSetFieldDarcy
  TYPE(cmfe_FieldType) :: EquationsSetFieldMatProperties
  !   TYPE(cmfe_FieldType) :: IndependentFieldDarcy
  !   TYPE(cmfe_FieldType) :: IndependentFieldMatProperties
  TYPE(cmfe_BoundaryConditionsType) :: BoundaryConditionsDarcy
  TYPE(cmfe_BoundaryConditionsType) :: BoundaryConditionsMatProperties
  TYPE(cmfe_EquationsSetType) :: EquationsSetDarcy
  TYPE(cmfe_EquationsSetType) :: EquationsSetMatProperties
  TYPE(cmfe_EquationsType) :: EquationsDarcy
  TYPE(cmfe_EquationsType) :: EquationsMatProperties
  TYPE(cmfe_ProblemType) :: Problem
  TYPE(cmfe_ControlLoopType) :: ControlLoop
  TYPE(cmfe_SolverType) :: LinearSolverDarcy
  TYPE(cmfe_SolverType) :: LinearSolverMatProperties
  TYPE(cmfe_SolverEquationsType) :: SolverEquationsDarcy
  TYPE(cmfe_SolverEquationsType) :: SolverEquationsMatProperties

  !Generic CMISS variables

  INTEGER(CMISSIntg) :: NumberOfComputationalNodes,ComputationalNodeNumber,NodeDomain
  INTEGER(CMISSIntg) :: EquationsSetIndex,i,Err

  !
  !================================================================================================================================
  !

  !INITIALISE OPENCMISS

  CALL cmfe_Initialise(WorldCoordinateSystem,WorldRegion,Err)
  CALL cmfe_ErrorHandlingModeSet(CMFE_ERRORS_TRAP_ERROR,Err)

  !Get the computational nodes information
  CALL cmfe_ComputationEnvironment_Initialise(computationEnvironment,err)
  CALL cmfe_ComputationEnvironment_NumberOfWorldNodesGet(computationEnvironment,numberOfComputationalNodes,err)
  CALL cmfe_ComputationEnvironment_WorldNodeNumberGet(computationEnvironment,computationalNodeNumber,err)

  !
  !================================================================================================================================
  !

  !PROBLEM CONTROL PANEL
  NUMBER_GLOBAL_X_ELEMENTS=3
  NUMBER_GLOBAL_Y_ELEMENTS=3
  NUMBER_GLOBAL_Z_ELEMENTS=3
  NUMBER_OF_DIMENSIONS=3
  BASIS_TYPE=CMFE_BASIS_LINEAR_LAGRANGE_INTERPOLATION
  BASIS_XI_INTERPOLATION_GEOMETRY=CMFE_BASIS_LINEAR_LAGRANGE_INTERPOLATION
  BASIS_XI_INTERPOLATION_VELOCITY=CMFE_BASIS_LINEAR_LAGRANGE_INTERPOLATION
  BASIS_XI_INTERPOLATION_PRESSURE=CMFE_BASIS_LINEAR_LAGRANGE_INTERPOLATION
  MESH_COMPONENT_NUMBER_GEOMETRY=1
  MESH_COMPONENT_NUMBER_VELOCITY=1
  MESH_COMPONENT_NUMBER_PRESSURE=1
  !Set initial values
  INITIAL_FIELD_DARCY(1)=0.0_CMISSRP
  INITIAL_FIELD_DARCY(2)=0.0_CMISSRP
  INITIAL_FIELD_DARCY(3)=0.0_CMISSRP
  INITIAL_FIELD_MAT_PROPERTIES(1)=0.0_CMISSRP
  INITIAL_FIELD_MAT_PROPERTIES(2)=0.0_CMISSRP
  INITIAL_FIELD_MAT_PROPERTIES(3)=0.0_CMISSRP
  !Set material parameters
  POROSITY_PARAM_DARCY=0.3_CMISSRP
  PERM_OVER_VIS_PARAM_DARCY=1.0_CMISSRP
  POROSITY_PARAM_MAT_PROPERTIES=POROSITY_PARAM_DARCY
  PERM_OVER_VIS_PARAM_MAT_PROPERTIES=PERM_OVER_VIS_PARAM_DARCY
  !Set number of Gauss points
  BASIS_XI_GAUSS_GEOMETRY=3
  BASIS_XI_GAUSS_VELOCITY=3
  BASIS_XI_GAUSS_PRESSURE=3
  !Set output parameter
  !(NoOutput/ProgressOutput/TimingOutput/SolverOutput/SolverMatrixOutput)
  LINEAR_SOLVER_MAT_PROPERTIES_OUTPUT_TYPE=CMFE_SOLVER_NO_OUTPUT
  LINEAR_SOLVER_DARCY_OUTPUT_TYPE=CMFE_SOLVER_NO_OUTPUT
  !(NoOutput/TimingOutput/MatrixOutput/ElementOutput)
  EQUATIONS_DARCY_OUTPUT=CMFE_EQUATIONS_NO_OUTPUT
  EQUATIONS_MAT_PROPERTIES_OUTPUT=CMFE_EQUATIONS_NO_OUTPUT
  !Set time parameter
  LINEAR_SOLVER_DARCY_START_TIME=0.0_CMISSRP
  LINEAR_SOLVER_DARCY_STOP_TIME=1.125_CMISSRP
  LINEAR_SOLVER_DARCY_TIME_INCREMENT=0.125_CMISSRP
  !Set result output parameter
  LINEAR_SOLVER_DARCY_OUTPUT_FREQUENCY=1
  !Set solver parameters
  LINEAR_SOLVER_MAT_PROPERTIES_DIRECT_FLAG=.FALSE.
  LINEAR_SOLVER_DARCY_DIRECT_FLAG=.FALSE.
  RELATIVE_TOLERANCE=1.0E-10_CMISSRP !default: 1.0E-05_CMISSRP
  ABSOLUTE_TOLERANCE=1.0E-10_CMISSRP !default: 1.0E-10_CMISSRP
  DIVERGENCE_TOLERANCE=1.0E5_CMISSRP !default: 1.0E5
  MAXIMUM_ITERATIONS=10000_CMISSIntg !default: 100000
  RESTART_VALUE=3000_CMISSIntg !default: 30
  LINESEARCH_ALPHA=1.0_CMISSRP

  !
  !================================================================================================================================
  !

  !COORDINATE SYSTEM

  !Start the creation of a new RC coordinate system
  CALL cmfe_CoordinateSystem_Initialise(CoordinateSystem,Err)
  CALL cmfe_CoordinateSystem_CreateStart(CoordinateSystemUserNumber,CoordinateSystem,Err)
  !Set the coordinate system dimension
  CALL cmfe_CoordinateSystem_DimensionSet(CoordinateSystem,NUMBER_OF_DIMENSIONS,Err)
  !Finish the creation of the coordinate system
  CALL cmfe_CoordinateSystem_CreateFinish(CoordinateSystem,Err)

  !
  !================================================================================================================================
  !

  !REGION

  !Start the creation of a new region
  CALL cmfe_Region_Initialise(Region,Err)
  CALL cmfe_Region_CreateStart(RegionUserNumber,WorldRegion,Region,Err)
  CALL cmfe_Region_LabelSet(Region,"DarcyRegion",Err)
  !Set the regions coordinate system as defined above
  CALL cmfe_Region_CoordinateSystemSet(Region,CoordinateSystem,Err)
  !Finish the creation of the region
  CALL cmfe_Region_CreateFinish(Region,Err)

  !
  !================================================================================================================================
  !

  !BASES

  !Start the creation of new bases
  MESH_NUMBER_OF_COMPONENTS=1
  CALL cmfe_Basis_Initialise(BasisGeometry,Err)
  CALL cmfe_Basis_CreateStart(BASIS_NUMBER_GEOMETRY,BasisGeometry,Err)
  !Set the basis type (Lagrange/Simplex)
  CALL cmfe_Basis_TypeSet(BasisGeometry,BASIS_TYPE,Err)
  !Set the basis xi number
  CALL cmfe_Basis_NumberOfXiSet(BasisGeometry,NUMBER_OF_DIMENSIONS,Err)
  !Set the basis xi interpolation and number of Gauss points
  IF(NUMBER_OF_DIMENSIONS==2) THEN
     CALL cmfe_Basis_InterpolationXiSet(BasisGeometry,[BASIS_XI_INTERPOLATION_GEOMETRY,BASIS_XI_INTERPOLATION_GEOMETRY],Err)
     CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(BasisGeometry,[BASIS_XI_GAUSS_GEOMETRY,BASIS_XI_GAUSS_GEOMETRY],Err)
  ELSE
     CALL cmfe_Basis_InterpolationXiSet(BasisGeometry,[BASIS_XI_INTERPOLATION_GEOMETRY,BASIS_XI_INTERPOLATION_GEOMETRY, &
          & BASIS_XI_INTERPOLATION_GEOMETRY],Err)
     CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(BasisGeometry,[BASIS_XI_GAUSS_GEOMETRY,BASIS_XI_GAUSS_GEOMETRY, &
          & BASIS_XI_GAUSS_GEOMETRY],Err)
     CALL cmfe_Basis_QuadratureLocalFaceGaussEvaluateSet(BasisGeometry,.TRUE.,Err)
  ENDIF

  !Finish the creation of the basis
  CALL cmfe_Basis_CreateFinish(BasisGeometry,Err)

  !Start the creation of another basis
  IF(BASIS_XI_INTERPOLATION_VELOCITY==BASIS_XI_INTERPOLATION_GEOMETRY) THEN
     BasisVelocity=BasisGeometry
  ELSE
     MESH_NUMBER_OF_COMPONENTS=MESH_NUMBER_OF_COMPONENTS+1
     !Initialise a new velocity basis
     CALL cmfe_Basis_Initialise(BasisVelocity,Err)
     !Start the creation of a basis
     CALL cmfe_Basis_CreateStart(BASIS_NUMBER_VELOCITY,BasisVelocity,Err)
     !Set the basis type (Lagrange/Simplex)
     CALL cmfe_Basis_TypeSet(BasisVelocity,BASIS_TYPE,Err)
     !Set the basis xi number
     CALL cmfe_Basis_NumberOfXiSet(BasisVelocity,NUMBER_OF_DIMENSIONS,Err)
     !Set the basis xi interpolation and number of Gauss points
     IF(NUMBER_OF_DIMENSIONS==2) THEN
        CALL cmfe_Basis_InterpolationXiSet(BasisVelocity,[BASIS_XI_INTERPOLATION_VELOCITY,BASIS_XI_INTERPOLATION_VELOCITY],Err)
        CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(BasisVelocity,[BASIS_XI_GAUSS_VELOCITY,BASIS_XI_GAUSS_VELOCITY],Err)
     ELSE
        CALL cmfe_Basis_InterpolationXiSet(BasisVelocity,[BASIS_XI_INTERPOLATION_VELOCITY,BASIS_XI_INTERPOLATION_VELOCITY, &
             & BASIS_XI_INTERPOLATION_VELOCITY],Err)
        CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(BasisVelocity,[BASIS_XI_GAUSS_VELOCITY,BASIS_XI_GAUSS_VELOCITY, &
             & BASIS_XI_GAUSS_VELOCITY],Err)
        CALL cmfe_Basis_QuadratureLocalFaceGaussEvaluateSet(BasisVelocity,.TRUE.,Err)
     ENDIF
     !Finish the creation of the basis
     CALL cmfe_Basis_CreateFinish(BasisVelocity,Err)
  ENDIF

  !Start the creation of another basis
  IF(BASIS_XI_INTERPOLATION_PRESSURE==BASIS_XI_INTERPOLATION_GEOMETRY) THEN
     BasisPressure=BasisGeometry
  ELSE IF(BASIS_XI_INTERPOLATION_PRESSURE==BASIS_XI_INTERPOLATION_VELOCITY) THEN
     BasisPressure=BasisVelocity
  ELSE
     MESH_NUMBER_OF_COMPONENTS=MESH_NUMBER_OF_COMPONENTS+1
     !Initialise a new pressure basis
     CALL cmfe_Basis_Initialise(BasisPressure,Err)
     !Start the creation of a basis
     CALL cmfe_Basis_CreateStart(BASIS_NUMBER_PRESSURE,BasisPressure,Err)
     !Set the basis type (Lagrange/Simplex)
     CALL cmfe_Basis_TypeSet(BasisPressure,BASIS_TYPE,Err)
     !Set the basis xi number
     CALL cmfe_Basis_NumberOfXiSet(BasisPressure,NUMBER_OF_DIMENSIONS,Err)
     !Set the basis xi interpolation and number of Gauss points
     IF(NUMBER_OF_DIMENSIONS==2) THEN
        CALL cmfe_Basis_InterpolationXiSet(BasisPressure,[BASIS_XI_INTERPOLATION_PRESSURE,BASIS_XI_INTERPOLATION_PRESSURE],Err)
        CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(BasisPressure,[BASIS_XI_GAUSS_PRESSURE,BASIS_XI_GAUSS_PRESSURE],Err)
     ELSE
        CALL cmfe_Basis_InterpolationXiSet(BasisPressure,[BASIS_XI_INTERPOLATION_PRESSURE,BASIS_XI_INTERPOLATION_PRESSURE, &
             & BASIS_XI_INTERPOLATION_PRESSURE],Err)
        CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(BasisPressure,[BASIS_XI_GAUSS_PRESSURE,BASIS_XI_GAUSS_PRESSURE, &
             & BASIS_XI_GAUSS_PRESSURE],Err)
        CALL cmfe_Basis_QuadratureLocalFaceGaussEvaluateSet(BasisPressure,.TRUE.,Err)
     ENDIF
     !Finish the creation of the basis
     CALL cmfe_Basis_CreateFinish(BasisPressure,Err)
  ENDIF

  !
  !================================================================================================================================
  !

  !MESH

  !Start the creation of a generated mesh in the region
  CALL cmfe_GeneratedMesh_Initialise(GeneratedMesh,Err)
  CALL cmfe_GeneratedMesh_CreateStart(GeneratedMeshUserNumber,Region,GeneratedMesh,Err)
  !Set up a regular x*y*z mesh
  CALL cmfe_GeneratedMesh_TypeSet(GeneratedMesh,CMFE_GENERATED_MESH_REGULAR_MESH_TYPE,Err)
  !Set the default basis
  CALL cmfe_GeneratedMesh_BasisSet(GeneratedMesh,BasisGeometry,Err)
  !Define the mesh on the region
  IF(NUMBER_OF_DIMENSIONS==2) THEN
     CALL cmfe_GeneratedMesh_ExtentSet(GeneratedMesh,[WIDTH,HEIGHT],Err)
     CALL cmfe_GeneratedMesh_NumberOfElementsSet(GeneratedMesh,[NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS],Err)
  ELSE
     CALL cmfe_GeneratedMesh_ExtentSet(GeneratedMesh,[WIDTH,HEIGHT,LENGTH],Err)
     CALL cmfe_GeneratedMesh_NumberOfElementsSet(GeneratedMesh,[NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS, &
          & NUMBER_GLOBAL_Z_ELEMENTS],Err)
  ENDIF
  !Finish the creation of a generated mesh in the region
  CALL cmfe_Mesh_Initialise(Mesh,Err)
  CALL cmfe_GeneratedMesh_CreateFinish(GeneratedMesh,MeshUserNumber,Mesh,Err)

  !
  !================================================================================================================================
  !

  !DECOMPOSITION

  !Create a decomposition
  CALL cmfe_Decomposition_Initialise(Decomposition,Err)
  CALL cmfe_Decomposition_CreateStart(DecompositionUserNumber,Mesh,Decomposition,Err)
  !Set the decomposition to be a general decomposition with the specified number of domains
  CALL cmfe_Decomposition_TypeSet(Decomposition,CMFE_DECOMPOSITION_CALCULATED_TYPE,Err)
  CALL cmfe_Decomposition_NumberOfDomainsSet(Decomposition,NumberOfComputationalNodes,Err)
  !Finish the decomposition
  CALL cmfe_Decomposition_CreateFinish(Decomposition,Err)

  !
  !================================================================================================================================
  !

  !GEOMETRIC FIELD

  !Start to create a default (geometric) field on the region
  CALL cmfe_Field_Initialise(GeometricField,Err)
  CALL cmfe_Field_CreateStart(GeometricFieldUserNumber,Region,GeometricField,Err)
  !Set the field type
  CALL cmfe_Field_TypeSet(GeometricField,CMFE_FIELD_GEOMETRIC_TYPE,Err)
  !Set the decomposition to use
  CALL cmfe_Field_MeshDecompositionSet(GeometricField,Decomposition,Err)
  !Set the scaling to use
  CALL cmfe_Field_ScalingTypeSet(GeometricField,CMFE_FIELD_NO_SCALING,Err)
  !Set the mesh component to be used by the field components.
  DO COMPONENT_NUMBER=1,NUMBER_OF_DIMENSIONS
     CALL cmfe_Field_ComponentMeshComponentSet(GeometricField,CMFE_FIELD_U_VARIABLE_TYPE,COMPONENT_NUMBER, &
          & MESH_COMPONENT_NUMBER_GEOMETRY,Err)
  ENDDO
  !Finish creating the field
  CALL cmfe_Field_CreateFinish(GeometricField,Err)
  !Update the geometric field parameters
  CALL cmfe_GeneratedMesh_GeometricParametersCalculate(GeneratedMesh,GeometricField,Err)
  !
  !================================================================================================================================
  !

  !EQUATIONS SETS

  !Create the equations set for ALE Darcy
  CALL cmfe_Field_Initialise(EquationsSetFieldDarcy,Err)
  CALL cmfe_EquationsSet_Initialise(EquationsSetDarcy,Err)
  !Set the equations set to be a ALE Darcy problem
  CALL cmfe_EquationsSet_CreateStart(EquationsSetUserNumberDarcy,Region,GeometricField,[CMFE_EQUATIONS_SET_FLUID_MECHANICS_CLASS, &
       & CMFE_EQUATIONS_SET_DARCY_EQUATION_TYPE,CMFE_EQUATIONS_SET_ALE_DARCY_SUBTYPE],EquationsSetFieldUserNumberDarcy, &
       & EquationsSetFieldDarcy,EquationsSetDarcy,Err)
  !Finish creating the equations set
  CALL cmfe_EquationsSet_CreateFinish(EquationsSetDarcy,Err)

  !Create the equations set for deformation-dependent material properties
  CALL cmfe_Field_Initialise(EquationsSetFieldMatProperties,Err)
  CALL cmfe_EquationsSet_Initialise(EquationsSetMatProperties,Err)
  !Set the equations set to be a deformation-dependent material properties problem
  CALL cmfe_EquationsSet_CreateStart(EquationsSetUserNumberMatProperties,Region,GeometricField,[CMFE_EQUATIONS_SET_FITTING_CLASS, &
       & CMFE_EQUATIONS_SET_DATA_FITTING_EQUATION_TYPE,CMFE_EQUATIONS_SET_MAT_PROPERTIES_DATA_FITTING_SUBTYPE, &
       & CMFE_EQUATIONS_SET_FITTING_NO_SMOOTHING],EquationsSetFieldUserNumberMatProperties,EquationsSetFieldMatProperties, &
       & EquationsSetMatProperties,Err)
  !Finish creating the equations set
  CALL cmfe_EquationsSet_CreateFinish(EquationsSetMatProperties,Err)

  !
  !================================================================================================================================
  !

  !DEPENDENT FIELDS

  !Create the equations set dependent field variables for ALE Darcy
  CALL cmfe_Field_Initialise(DependentFieldDarcy,Err)
  CALL cmfe_EquationsSet_DependentCreateStart(EquationsSetDarcy,DependentFieldUserNumberDarcy, &
       & DependentFieldDarcy,Err)
  !Set the mesh component to be used by the field components.
  DO COMPONENT_NUMBER=1,NUMBER_OF_DIMENSIONS
     CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,COMPONENT_NUMBER, &
          & MESH_COMPONENT_NUMBER_VELOCITY,Err)
     CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldDarcy,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,COMPONENT_NUMBER, &
          & MESH_COMPONENT_NUMBER_VELOCITY,Err)
  ENDDO
  COMPONENT_NUMBER=NUMBER_OF_DIMENSIONS+1
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,COMPONENT_NUMBER, &
       & MESH_COMPONENT_NUMBER_PRESSURE,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldDarcy,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,COMPONENT_NUMBER, &
       & MESH_COMPONENT_NUMBER_PRESSURE,Err)
  !Finish the equations set dependent field variables
  CALL cmfe_EquationsSet_DependentCreateFinish(EquationsSetDarcy,Err)

  !Initialise dependent field (velocity components)
  DO COMPONENT_NUMBER=1,NUMBER_OF_DIMENSIONS
     CALL cmfe_Field_ComponentValuesInitialise(DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
          & COMPONENT_NUMBER,INITIAL_FIELD_DARCY(COMPONENT_NUMBER),Err)
  ENDDO

  !Create the equations set dependent field variables for deformation-dependent material properties
  CALL cmfe_Field_Initialise(DependentFieldMatProperties,Err)
  CALL cmfe_EquationsSet_DependentCreateStart(EquationsSetMatProperties,DependentFieldUserNumberMatProperties, &
       & DependentFieldMatProperties,Err)
  !Set the mesh component to be used by the field components.
  NUMBER_OF_COMPONENTS_DEPENDENT_FIELD_MAT_PROPERTIES=2
  DO COMPONENT_NUMBER=1,NUMBER_OF_COMPONENTS_DEPENDENT_FIELD_MAT_PROPERTIES
     CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldMatProperties,CMFE_FIELD_U_VARIABLE_TYPE,COMPONENT_NUMBER, &
          & MESH_COMPONENT_NUMBER_GEOMETRY,Err)
     CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldMatProperties,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,COMPONENT_NUMBER, &
          & MESH_COMPONENT_NUMBER_GEOMETRY,Err)
  ENDDO
  !Finish the equations set dependent field variables
  CALL cmfe_EquationsSet_DependentCreateFinish(EquationsSetMatProperties,Err)

  !Initialise dependent field
  DO COMPONENT_NUMBER=1,NUMBER_OF_COMPONENTS_DEPENDENT_FIELD_MAT_PROPERTIES
     CALL cmfe_Field_ComponentValuesInitialise(DependentFieldMatProperties,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
          & COMPONENT_NUMBER,INITIAL_FIELD_MAT_PROPERTIES(COMPONENT_NUMBER),Err)
  ENDDO

  !
  !================================================================================================================================
  !

  !MATERIALS FIELDS

  !Create the equations set materials field variables for ALE Darcy
  CALL cmfe_Field_Initialise(MaterialsFieldDarcy,Err)
  CALL cmfe_EquationsSet_MaterialsCreateStart(EquationsSetDarcy,MaterialsFieldUserNumberDarcy, &
       & MaterialsFieldDarcy,Err)
  !Finish the equations set materials field variables
  CALL cmfe_EquationsSet_MaterialsCreateFinish(EquationsSetDarcy,Err)
  CALL cmfe_Field_ComponentValuesInitialise(MaterialsFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
       & MaterialsFieldUserNumberDarcyPorosity,POROSITY_PARAM_DARCY,Err)
  CALL cmfe_Field_ComponentValuesInitialise(MaterialsFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
       & MaterialsFieldUserNumberDarcyPermOverVis,PERM_OVER_VIS_PARAM_DARCY,Err)
  !Create the equations set materials field variables for deformation-dependent material properties
  CALL cmfe_Field_Initialise(MaterialsFieldMatProperties,Err)
  CALL cmfe_EquationsSet_MaterialsCreateStart(EquationsSetMatProperties,MaterialsFieldUserNumberMatProperties, &
       & MaterialsFieldMatProperties,Err)
  !Finish the equations set materials field variables
  CALL cmfe_EquationsSet_MaterialsCreateFinish(EquationsSetMatProperties,Err)
  CALL cmfe_Field_ComponentValuesInitialise(MaterialsFieldMatProperties,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
       & MaterialsFieldUserNumberMatPropertiesPorosity,POROSITY_PARAM_MAT_PROPERTIES,Err)
  CALL cmfe_Field_ComponentValuesInitialise(MaterialsFieldMatProperties,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
       & MaterialsFieldUserNumberMatPropertiesPermOverVis,PERM_OVER_VIS_PARAM_MAT_PROPERTIES,Err)

  !
  !================================================================================================================================
  !

  !   !INDEPENDENT FIELDS
  !
  !   !Create the equations set independent field variables for ALE Darcy
  !   CALL cmfe_Field_Initialise(IndependentFieldDarcy,Err)
  !   CALL cmfe_EquationsSet_IndependentCreateStart(EquationsSetDarcy,IndependentFieldUserNumberDarcy, &
  !     & IndependentFieldDarcy,Err)
  !   !Set the mesh component to be used by the field components.
  !   DO COMPONENT_NUMBER=1,NUMBER_OF_DIMENSIONS+1
  !     CALL cmfe_Field_ComponentMeshComponentSet(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,COMPONENT_NUMBER, &
  !       & MESH_COMPONENT_NUMBER_GEOMETRY,Err)
  !   ENDDO
  !   !Finish the equations set independent field variables
  !   CALL cmfe_EquationsSet_IndependentCreateFinish(EquationsSetDarcy,Err)
  !   !Create the equations set independent field variables for deformation-dependent material properties
  !   CALL cmfe_Field_Initialise(IndependentFieldMatProperties,Err)
  !   CALL cmfe_EquationsSet_IndependentCreateStart(EquationsSetMatProperties,IndependentFieldUserNumberMatProperties, &
  !     & IndependentFieldMatProperties,Err)
  !   !Set the mesh component to be used by the field components.
  !   DO COMPONENT_NUMBER=1,NUMBER_OF_DIMENSIONS
  !     CALL cmfe_Field_ComponentMeshComponentSet(IndependentFieldMatProperties,CMFE_FIELD_U_VARIABLE_TYPE,COMPONENT_NUMBER, &
  !       & MESH_COMPONENT_NUMBER_GEOMETRY,Err)
  !   ENDDO
  !   !Finish the equations set independent field variables
  !   CALL cmfe_EquationsSet_IndependentCreateFinish(EquationsSetMatProperties,Err)

  !
  !================================================================================================================================
  !

  !EQUATIONS

  !Create the equations set equations
  CALL cmfe_Equations_Initialise(EquationsDarcy,Err)
  CALL cmfe_EquationsSet_EquationsCreateStart(EquationsSetDarcy,EquationsDarcy,Err)
  !Set the equations matrices sparsity type
  CALL cmfe_Equations_SparsityTypeSet(EquationsDarcy,CMFE_EQUATIONS_SPARSE_MATRICES,Err)
  !Set the equations set output
  CALL cmfe_Equations_OutputTypeSet(EquationsDarcy,EQUATIONS_DARCY_OUTPUT,Err)
  !Finish the equations set equations
  CALL cmfe_EquationsSet_EquationsCreateFinish(EquationsSetDarcy,Err)

  !Create the equations set equations
  CALL cmfe_Equations_Initialise(EquationsMatProperties,Err)
  CALL cmfe_EquationsSet_EquationsCreateStart(EquationsSetMatProperties,EquationsMatProperties,Err)
  !Set the equations matrices sparsity type
  CALL cmfe_Equations_SparsityTypeSet(EquationsMatProperties,CMFE_EQUATIONS_SPARSE_MATRICES,Err)
  !Set the equations set output
  CALL cmfe_Equations_OutputTypeSet(EquationsMatProperties,EQUATIONS_MAT_PROPERTIES_OUTPUT,Err)
  !Finish the equations set equations
  CALL cmfe_EquationsSet_EquationsCreateFinish(EquationsSetMatProperties,Err)

  !
  !================================================================================================================================
  !

  !PROBLEMS

  !Start the creation of a problem.
  CALL cmfe_Problem_Initialise(Problem,Err)
  CALL cmfe_ControlLoop_Initialise(ControlLoop,Err)
  CALL cmfe_Problem_CreateStart(ProblemUserNumber,[CMFE_PROBLEM_FLUID_MECHANICS_CLASS,CMFE_PROBLEM_DARCY_EQUATION_TYPE, &
       & CMFE_PROBLEM_ALE_DARCY_SUBTYPE],Problem,Err)
  !Finish the creation of a problem.
  CALL cmfe_Problem_CreateFinish(Problem,Err)
  !Start the creation of the problem control loop
  CALL cmfe_Problem_ControlLoopCreateStart(Problem,Err)
  !Get the control loop
  CALL cmfe_Problem_ControlLoopGet(Problem,CMFE_CONTROL_LOOP_NODE,ControlLoop,Err)
  !Set the times
  CALL cmfe_ControlLoop_TimesSet(ControlLoop,LINEAR_SOLVER_DARCY_START_TIME,LINEAR_SOLVER_DARCY_STOP_TIME, &
       & LINEAR_SOLVER_DARCY_TIME_INCREMENT,Err)
  !Set the output timing
  CALL cmfe_ControlLoop_OutputTypeSet(ControlLoop,CMFE_CONTROL_LOOP_PROGRESS_OUTPUT,Err)
  CALL cmfe_ControlLoop_TimeOutputSet(ControlLoop,LINEAR_SOLVER_DARCY_OUTPUT_FREQUENCY,Err)
  !Finish creating the problem control loop
  CALL cmfe_Problem_ControlLoopCreateFinish(Problem,Err)

  !
  !================================================================================================================================
  !

  !SOLVERS

  !Start the creation of the problem solvers
  CALL cmfe_Solver_Initialise(LinearSolverMatProperties,Err)
  CALL cmfe_Solver_Initialise(LinearSolverDarcy,Err)
  CALL cmfe_Problem_SolversCreateStart(Problem,Err)
  !Get the deformation-dependent material properties solver
  CALL cmfe_Problem_SolverGet(Problem,CMFE_CONTROL_LOOP_NODE,SolverMatPropertiesUserNumber,LinearSolverMatProperties,Err)
  !Set the output type
  CALL cmfe_Solver_OutputTypeSet(LinearSolverMatProperties,LINEAR_SOLVER_MAT_PROPERTIES_OUTPUT_TYPE,Err)
  !Set the solver settings
  IF(LINEAR_SOLVER_MAT_PROPERTIES_DIRECT_FLAG) THEN
     CALL cmfe_Solver_LinearTypeSet(LinearSolverMatProperties,CMFE_SOLVER_LINEAR_DIRECT_SOLVE_TYPE,Err)
     CALL cmfe_Solver_LibraryTypeSet(LinearSolverMatProperties,CMFE_SOLVER_MUMPS_LIBRARY,Err)
  ELSE
     CALL cmfe_Solver_LinearTypeSet(LinearSolverMatProperties,CMFE_SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE,Err)
     CALL cmfe_Solver_LinearIterativeMaximumIterationsSet(LinearSolverMatProperties,MAXIMUM_ITERATIONS,Err)
     CALL cmfe_Solver_LinearIterativeDivergenceToleranceSet(LinearSolverMatProperties,DIVERGENCE_TOLERANCE,Err)
     CALL cmfe_Solver_LinearIterativeRelativeToleranceSet(LinearSolverMatProperties,RELATIVE_TOLERANCE,Err)
     CALL cmfe_Solver_LinearIterativeAbsoluteToleranceSet(LinearSolverMatProperties,ABSOLUTE_TOLERANCE,Err)
     CALL cmfe_Solver_LinearIterativeGMRESRestartSet(LinearSolverMatProperties,RESTART_VALUE,Err)
  ENDIF
  !Get the Darcy solver
  CALL cmfe_Problem_SolverGet(Problem,CMFE_CONTROL_LOOP_NODE,SolverDarcyUserNumber,LinearSolverDarcy,Err)
  !Set the output type
  CALL cmfe_Solver_OutputTypeSet(LinearSolverDarcy,LINEAR_SOLVER_DARCY_OUTPUT_TYPE,Err)
  !Set the solver settings
  IF(LINEAR_SOLVER_DARCY_DIRECT_FLAG) THEN
     CALL cmfe_Solver_LinearTypeSet(LinearSolverDarcy,CMFE_SOLVER_LINEAR_DIRECT_SOLVE_TYPE,Err)
     CALL cmfe_Solver_LibraryTypeSet(LinearSolverDarcy,CMFE_SOLVER_MUMPS_LIBRARY,Err)
  ELSE
     CALL cmfe_Solver_LinearTypeSet(LinearSolverDarcy,CMFE_SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE,Err)
     CALL cmfe_Solver_LinearIterativeMaximumIterationsSet(LinearSolverDarcy,MAXIMUM_ITERATIONS,Err)
     CALL cmfe_Solver_LinearIterativeDivergenceToleranceSet(LinearSolverDarcy,DIVERGENCE_TOLERANCE,Err)
     CALL cmfe_Solver_LinearIterativeRelativeToleranceSet(LinearSolverDarcy,RELATIVE_TOLERANCE,Err)
     CALL cmfe_Solver_LinearIterativeAbsoluteToleranceSet(LinearSolverDarcy,ABSOLUTE_TOLERANCE,Err)
     CALL cmfe_Solver_LinearIterativeGMRESRestartSet(LinearSolverDarcy,RESTART_VALUE,Err)
  ENDIF
  !Finish the creation of the problem solver
  CALL cmfe_Problem_SolversCreateFinish(Problem,Err)

  !
  !================================================================================================================================
  !

  !SOLVER EQUATIONS

  !Start the creation of the problem solver equations
  CALL cmfe_Solver_Initialise(LinearSolverMatProperties,Err)
  CALL cmfe_Solver_Initialise(LinearSolverDarcy,Err)
  CALL cmfe_SolverEquations_Initialise(SolverEquationsMatProperties,Err)
  CALL cmfe_SolverEquations_Initialise(SolverEquationsDarcy,Err)

  CALL cmfe_Problem_SolverEquationsCreateStart(Problem,Err)
  !Get the deformation-dependent material properties solver equations
  CALL cmfe_Problem_SolverGet(Problem,CMFE_CONTROL_LOOP_NODE,SolverMatPropertiesUserNumber,LinearSolverMatProperties,Err)
  CALL cmfe_Solver_SolverEquationsGet(LinearSolverMatProperties,SolverEquationsMatProperties,Err)
  !Set the solver equations sparsity
  CALL cmfe_SolverEquations_SparsityTypeSet(SolverEquationsMatProperties,CMFE_SOLVER_SPARSE_MATRICES,Err)
  !Add in the equations set
  CALL cmfe_SolverEquations_EquationsSetAdd(SolverEquationsMatProperties,EquationsSetMatProperties,EquationsSetIndex,Err)
  !Finish the creation of the problem solver equations
  !Get the Darcy solver equations
  CALL cmfe_Problem_SolverGet(Problem,CMFE_CONTROL_LOOP_NODE,SolverDarcyUserNumber,LinearSolverDarcy,Err)
  CALL cmfe_Solver_SolverEquationsGet(LinearSolverDarcy,SolverEquationsDarcy,Err)
  !Set the solver equations sparsity
  CALL cmfe_SolverEquations_SparsityTypeSet(SolverEquationsDarcy,CMFE_SOLVER_SPARSE_MATRICES,Err)
  !Add in the equations set
  CALL cmfe_SolverEquations_EquationsSetAdd(SolverEquationsDarcy,EquationsSetDarcy,EquationsSetIndex,Err)
  !Finish the creation of the problem solver equations
  CALL cmfe_Problem_SolverEquationsCreateFinish(Problem,Err)

  !
  !================================================================================================================================
  !

  !BOUNDARY CONDITIONS
  !Start the creation of the equations set boundary conditions for Darcy
  CALL cmfe_BoundaryConditions_Initialise(BoundaryConditionsDarcy,Err)
  CALL cmfe_SolverEquations_BoundaryConditionsCreateStart(SolverEquationsDarcy,BoundaryConditionsDarcy,Err)

  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 1,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 2,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 3,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 4,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 5,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 6,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 7,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 8,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 9,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 10,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 11,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 12,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 13,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 14,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 15,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)
  CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
       & 16,3,CMFE_BOUNDARY_CONDITION_FIXED,1.0_CMISSRP,Err)

  DO i=1,64
     CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
          & i,1,CMFE_BOUNDARY_CONDITION_FIXED,0.0_CMISSRP,Err)
     CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,1, &
          & i,2,CMFE_BOUNDARY_CONDITION_FIXED,0.0_CMISSRP,Err)
  END DO

  !Finish the creation of the equations set boundary conditions for Darcy
  CALL cmfe_SolverEquations_BoundaryConditionsCreateFinish(SolverEquationsDarcy,Err)
  !Start the creation of the equations set boundary conditions for deformation-dependent material properties
  CALL cmfe_BoundaryConditions_Initialise(BoundaryConditionsMatProperties,Err)
  CALL cmfe_SolverEquations_BoundaryConditionsCreateStart(SolverEquationsMatProperties,BoundaryConditionsMatProperties,Err)
  !(No boundary conditions requrired for deformation-dependent material properties)
  !Finish the creation of the equations set boundary conditions for deformation-dependent material properties
  CALL cmfe_SolverEquations_BoundaryConditionsCreateFinish(SolverEquationsMatProperties,Err)

  !
  !================================================================================================================================
  !

  !Solve the problem
  WRITE(*,'(A)') "Solving problem..."
  CALL cmfe_Problem_Solve(Problem,Err)
  WRITE(*,'(A)') "Problem solved!"

  !
  !================================================================================================================================
  !

  !OUTPUT

  EXPORT_FIELD_IO=.FALSE.
  IF(EXPORT_FIELD_IO) THEN
     WRITE(*,'(A)') "Exporting fields..."
     CALL cmfe_Fields_Initialise(Fields,Err)
     CALL cmfe_Fields_Create(Region,Fields,Err)
     CALL cmfe_Fields_NodesExport(Fields,"darcy_quasi","FORTRAN",Err)
     CALL cmfe_Fields_ElementsExport(Fields,"darcy_quasi","FORTRAN",Err)
     CALL cmfe_Fields_Finalise(Fields,Err)
     WRITE(*,'(A)') "Field exported!"
  ENDIF

  !Finialise CMISS
  CALL cmfe_Finalise(Err)
  WRITE(*,'(A)') "Program successfully completed."
  STOP

END PROGRAM darcy_quasistatic
