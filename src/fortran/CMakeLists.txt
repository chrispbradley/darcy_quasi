add_executable(darcy_quasi_fortran darcy_quasi.F90)

target_link_libraries(darcy_quasi_fortran PRIVATE opencmisslibs)

install(TARGETS darcy_quasi_fortran DESTINATION bin)
