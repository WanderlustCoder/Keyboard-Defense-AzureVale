extends SceneTree
## Headless balance verification runner
## Usage: godot --headless --path . --script res://tools/run_balance_check.gd

const BalanceVerifier = preload("res://sim/balance_verifier.gd")

func _init() -> void:
	print("")
	print("Running Balance Verification...")
	print("")

	var report := BalanceVerifier.generate_full_report()
	var formatted := BalanceVerifier.format_report(report)

	print(formatted)

	# Save report to file
	var file := FileAccess.open("res://balance_report.txt", FileAccess.WRITE)
	if file != null:
		file.store_string(formatted)
		file.close()
		print("")
		print("Report saved to: balance_report.txt")

	# Exit with appropriate code
	if report.get("passed", false):
		print("")
		print("Balance check PASSED")
		quit(0)
	else:
		print("")
		print("Balance check FAILED - review issues above")
		quit(1)
