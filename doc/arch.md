<table style="text-align:center">
<tr>
	<td colspan="7">On-board clock and I/O</td>
</tr>
<tr>
	<td colspan="7">⇅</td>
</tr>
<tr>
	<td colspan="7"><code>interface</code><br/>Signal exchange</td>
</tr>
<tr>
	<td>⇅</td>
	<td>⇅</td>
	<td>⇅</td>
	<td>⇅</td>
	<td colspan="3">⇅</td>
</tr>
<tr>
	<td><code>vending</code><br/>Core</td>
	<td><code>ip_clk</code><br/>Clock management</td>
	<td><code>frequency_divider</code><br/>Binary frequency division</td>
	<td><code>debouncer</code><br/>Signal debounce</td>
	<td colspan="3"><code>display</code><br/>Render</td>
</tr>
<tr>
	<td colspan="4" rowspan="2"></td>
	<td>⇅</td>
	<td>⇅</td>
	<td>⇅</td>
</tr>
<tr>
	<td><code>ip_bram_&lt;name&gt;</code><br/>BRAM</td>
	<td>…</td>
	<td><code>vga</code><br/>VGA timing</td>
</tr>
</table>