Prompt 1 (setup hiển thị cửa sổ ngữ cảnh  ) :

/statusline Show token count in compact form + percentage, format: "22.6k (2.0%)"
(round to 1 decimal place, use a dot as separator).

Color thresholds based on total_input_tokens:
- < 100k: green
- 100k to under 300k: yellow
- exactly 300k: orange
- > 300k: red

Requirements:
- Test the script by echoing sample JSON input for each threshold (0, 22600, 100000,
  150000, 200000, 250000 tokens) and show the actual output before declaring it done.
- Be careful to escape "%" correctly in printf (use %% or printf "%s").
- Make sure the script is executable (chmod +x) and statusLine is added to
  settings.json (merge, don't overwrite other keys).