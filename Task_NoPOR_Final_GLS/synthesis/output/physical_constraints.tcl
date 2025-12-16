#*************************************************
#  Created by Design Compiler Topographical write_floorplan
#  Version: T-2022.03-SP5
#  Date: Sun Dec 14 16:47:21 2025
#*************************************************
undo_config -disable
set oldSnapState [set_object_snap_type -enabled false]



#*************************************************
#   SECTION: Core Area
#*************************************************

remove_base_array -all



#*************************************************
#   SECTION: Site Rows, with number: 0
#*************************************************
cut_row -all 

update_floorplan

set_object_snap_type -enabled $oldSnapState

undo_config -enable
