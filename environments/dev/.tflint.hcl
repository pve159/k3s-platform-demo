- name: Setup TFLint
  uses: terraform-linters/setup-tflint@v4

- name: TFLint Init
  working-directory: ${{ env.TF_WORKING_DIR }}
  run: tflint --init

- name: Run TFLint
  working-directory: ${{ env.TF_WORKING_DIR }}
  run: |
    tflint --recursive | tee tflint.txt
    echo "## Terraform Lint Report" >> $GITHUB_STEP_SUMMARY
    echo "" >> $GITHUB_STEP_SUMMARY
    echo "**Environment:** dev" >> $GITHUB_STEP_SUMMARY
    echo "" >> $GITHUB_STEP_SUMMARY
    cat tflint.txt >> $GITHUB_STEP_SUMMARY
