
.SECONDEXPANSION:

%.ngc : $$($$*_VERILOG_SOURCES) $$(addprefix ipcore_dir/,$$(addsuffix .v,$$($$*_IPCORES)))
	@del $*.prj
	@for %%s in ($^) do echo verilog work "%%s" >> $*.prj
	@echo set -loop_iteration_limit 1000 > $*.xst 
	@echo run >> $*.xst 
	@echo -ifn $*.prj >> $*.xst 
	@echo -top $($*_TOP_MODULE) >> $*.xst 
	@echo -p $($*_DEVICE) >> $*.xst 
	@echo -ofn $@ >> $*.xst 
	@echo -opt_mode speed >> $*.xst 
	@echo -opt_level 1 >> $*.xst 
	@echo -netlist_hierarchy rebuilt >> $*.xst 
	$(XILINXBIN)/xst -ifn $*.xst -ofn $*.srp


%.ngd : %.ngc $$($$*_CONSTRAINT_FILES)
	$(XILINXBIN)/ngdbuild -p $($*_DEVICE) -dd _ngo -sd ipcore_dir $(foreach ucf,$($*_CONSTRAINT_FILES),-uc $(ucf)) $< $@

%_routed.ncd : %.ncd %.pcf
	$(XILINXBIN)/par -w $< $@

%.ncd %.pcf : %.ngd
	$(XILINXBIN)/map -p $($*_DEVICE) -timing -w -o $*.ncd $<

%.twr : %_routed.ncd %.pcf
	$(XILINXBIN)/trce -o $@ -v 12 -fastpaths $< $*.pcf

%.bit : %_routed.ncd %.pcf
#	$(XILINXBIN)/bitgen $< $@ $*.pcf -g Binary:Yes -g Compress -w
	$(XILINXBIN)/bitgen $< $@ $*.pcf -g Binary:Yes -w

#ipcore_dir/%.v: $(IPCORE_DIR)/%.xco ipcore_dir/coregen.cgc
#	$(XILINXBIN)/coregen -p ipcore_dir -b $<

#ipcore_dir/coregen.cgc : $(IPCORE_DIR)/coregen.cgc | ipcore_dir
#	cp $< $@

#ipcore_dir:
#	mkdir $@
