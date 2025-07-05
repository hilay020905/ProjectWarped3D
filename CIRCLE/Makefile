sim:
	verilator --trace -cc --top-module gpu gpu.v processor.v queue.v regs.v mem.v framebuffer_mem.v zbuffer_mem.v zbuffer.v --exe sim.cpp
	make -C obj_dir -j 8 -f Vgpu.mk Vgpu
	cp obj_dir/Vgpu sim

clean:
	rm -rf obj_dir sim output.bmp