cmake_minimum_required(VERSION 3.16)
project(indi_oag_focuser CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── Find INDI ─────────────────────────────────────────────────────────────────
find_package(INDI REQUIRED)
find_package(Nova REQUIRED)   # libnova — INDI dependency

include_directories(${INDI_INCLUDE_DIR})

# ── Driver target ─────────────────────────────────────────────────────────────
add_executable(indi_oag_focuser
    indi_oag_focuser.cpp
)

target_link_libraries(indi_oag_focuser
    ${INDI_LIBRARIES}
    ${NOVA_LIBRARIES}
    pthread
)

# ── Install ───────────────────────────────────────────────────────────────────
install(TARGETS indi_oag_focuser DESTINATION /usr/local/bin)
install(FILES   indi_oag_focuser.xml DESTINATION /usr/share/indi)
