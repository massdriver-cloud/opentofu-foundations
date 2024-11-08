.PHONY: prod.plan default.plan staging.plan
default.plan:
	tofu workspace select default
	tofu plan -var-file=default.auto.tfvars -out ./default.plan
	tofu show -json default.plan > default.json
	checkov -f default.json \
		--external-checks-dir . \
		--run-all-external-checks \
		--skip-check CKV_AWS_16,CKV_AWS_133,CKV_AWS_293,CKV_AWS_354,CKV_AWS_129,CKV_AWS_129,CKV_AWS_157,CKV_AWS_118,CKV_AWS_79,CKV_AWS_8,CKV_AWS_88,CKV_AWS_135,CKV_AWS_126,CKV_AWS_79,CKV_AWS_88,CKV_AWS_24,CKV_AWS_260,CKV2_AWS_60
	rm default.json default.plan
	
prod.plan:
	tofu workspace select production
	tofu plan -var-file=production.auto.tfvars -out ./production.plan
	tofu show -json production.plan > production.json
	checkov -f production.json
	rm production.json production.plan

staging.plan:
	tofu workspace select staging
	tofu plan -var-file=staging.auto.tfvars -out ./staging.plan
	tofu show -json staging.plan > staging.json
	checkov -f staging.json \
		--soft-fail \
		--external-checks-dir . \
		--run-all-external-checks \
		--skip-check CKV_AWS_16,CKV_AWS_133,CKV_AWS_293,CKV_AWS_354,CKV_AWS_129,CKV_AWS_129,CKV_AWS_157,CKV_AWS_118,CKV_AWS_79,CKV_AWS_8,CKV_AWS_88,CKV_AWS_135,CKV_AWS_126,CKV_AWS_79,CKV_AWS_88,CKV_AWS_24,CKV_AWS_260,CKV2_AWS_60
	rm staging.json staging.plan

.PHONY: staging.deploy prod.deploy default.deploy
staging.deploy:
	tofu workspace select staging
	tofu apply -var-file=staging.auto.tfvars

prod.deploy:
	tofu workspace select production
	tofu apply -var-file=production.auto.tfvars

default.deploy:
	tofu workspace select default
	tofu apply -var-file=default.auto.tfvars