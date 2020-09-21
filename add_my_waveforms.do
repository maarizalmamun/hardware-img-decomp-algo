# add waves to waveform
add wave Clock_50
add wave -divider {SRAM Data}
add wave uut/SRAM_we_n
add wave -hexadecimal uut/SRAM_write_data
add wave -hexadecimal -color Red uut/SRAM_read_data
add wave -unsigned uut/SRAM_address
add wave -hexadecimal uut/M2_SRAM_write_data
add wave -unsigned uut/m2_unit/counter_store_Sprime 

add wave -divider {STATES & STATELONG COUNTERS}
add wave -unsigned uut/m2_unit/M2_STATE
add wave -unsigned uut/m2_unit/counter_fetch_state
add wave -unsigned -color Red uut/m2_unit/counter_common_state
add wave -unsigned uut/m2_unit/counter_DRAM_read
add wave -unsigned uut/m2_unit/counter_DRAM_write
add wave -unsigned uut/m2_unit/counter_read_S_values

add wave -divider {DRAM Data}
add wave -unsigned uut/m2_unit/DRAM_we_n_a
add wave -unsigned uut/m2_unit/DRAM_we_n_b
add wave -unsigned uut/m2_unit/DRAM_address_a
add wave -unsigned uut/m2_unit/DRAM_address_b
add wave -decimal uut/m2_unit/DRAM_write_data_a
add wave -hexadecimal uut/m2_unit/DRAM_write_data_b
add wave -decimal -color red uut/m2_unit/DRAM_read_data_a
add wave -decimal uut/m2_unit/DRAM_read_data_b

add wave -divider {SRAM Reading/Writing Address Related}
add wave -decimal uut/m2_unit/ultimate_offset
add wave -decimal uut/m2_unit/ultimate_offset_write
add wave -decimal uut/m2_unit/counter_pixel 
add wave -unsigned uut/m2_unit/counter_row 
add wave -unsigned uut/m2_unit/counter_column 
add wave -unsigned uut/m2_unit/counter_pixel_write
add wave -unsigned uut/m2_unit/counter_row_write
add wave -unsigned uut/m2_unit/counter_column_write 
add wave -divider {iz_tingz}
add wave -unsigned uut/m2_unit/iz_y
add wave -unsigned uut/m2_unit/iz_u
add wave -unsigned uut/m2_unit/iz_y_write
add wave -unsigned uut/m2_unit/iz_u_write
add wave -unsigned uut/m2_unit/flag_complete
add wave -unsigned uut/m2_unit/flag_complete2
add wave -divider {Quik Mathz}
add wave -decimal -color Red uut/m2_unit/operator_0a
add wave -decimal uut/m2_unit/operator_0b
add wave -decimal -color Red uut/m2_unit/operator_1a
add wave -decimal uut/m2_unit/operator_1b
add wave -decimal uut/m2_unit/product_generator0
add wave -decimal uut/m2_unit/product_generator1
add wave -decimal uut/m2_unit/sum_compiler0
add wave -decimal uut/m2_unit/sum_compiler1
add wave -binary uut/m2_unit/S_is_life
add wave -hexadecimal uut/m2_unit/buffy_S

add wave -divider {M1 one }

add wave -divider {SRAM Data}
add wave uut/m1_unit/SRAM_we_n
add wave -hexadecimal -color Red uut/m1_unit/SRAM_write_data
add wave -hexadecimal -color Red uut/m1_unit/SRAM_read_data
add wave -unsigned uut//m1_unit/SRAM_address
add wave -unsigned uut//m1_unit/M1_STATE
add wave -unsigned uut//m1_unit/YVAL_sram_data
add wave -unsigned uut//m1_unit/UVAL_sram_data
add wave -unsigned uut//m1_unit/VVAL_sram_data
add wave -unsigned uut//m1_unit/RGB_even_data
add wave -unsigned uut//m1_unit/RGB_odd_data

