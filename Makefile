it:

.PHONY: consul
consul:
	$(MAKE) -C consul
.PHONY: openbao
openbao:
	$(MAKE) -C openbao
.PHONY: vault
vault:
	$(MAKE) -C vault
