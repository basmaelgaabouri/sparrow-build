$(ROOTDIR)/cache/renode: $(ROOTDIR)/sim/renode
	mkdir -p $(ROOTDIR)/cache/renode

renode: $(ROOTDIR)/cache/renode
	pushd $(ROOTDIR)/sim/renode; \
	    sed -i '/git submodule update/d' build.sh; \
	    ./build.sh; \
	    cp -rf output/bin/Release/* $(ROOTDIR)/cache/renode; \
	    cp -rf scripts $(ROOTDIR)/cache/renode; \
	    cp -rf platforms $(ROOTDIR)/cache/renode; \
	    git checkout build.sh;\
	popd

sim: renode

.PHONY:: renode sim
