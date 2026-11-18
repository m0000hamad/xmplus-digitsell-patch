{literal}
<style>
html[data-hs-theme="dark"] {
	color-scheme: dark;
	--night-text: #edf1fa;
	--night-muted: #b7c3d9;
	--night-surface: #272c3c;
	--night-hover: #353e58;
	--night-accent: #c7d2fe;
	--night-border: #677494;
}

/* Native popups may use their own background instead of the select's. */
html[data-hs-theme="dark"] select option,
html[data-hs-theme="dark"] select optgroup {
	background-color: var(--night-surface);
	color: var(--night-text);
}
html[data-hs-theme="dark"] select option:disabled {
	color: var(--night-muted);
}

html[data-hs-theme="dark"] .dropdown-menu,
html[data-hs-theme="dark"] .ts-dropdown {
	--bs-dropdown-bg: var(--night-surface);
	--bs-dropdown-color: var(--night-text);
	--bs-dropdown-header-color: var(--night-muted);
	--bs-dropdown-link-color: var(--night-text);
	--bs-dropdown-link-hover-color: var(--night-text);
	--bs-dropdown-link-hover-bg: var(--night-hover);
	--bs-dropdown-link-active-color: var(--night-text);
	--bs-dropdown-link-active-bg: var(--night-hover);
	--bs-dropdown-link-disabled-color: var(--night-muted);
	background-color: var(--night-surface);
	color: var(--night-text);
}
html[data-hs-theme="dark"] .dropdown-menu .dropdown-header,
html[data-hs-theme="dark"] .dropdown-menu .dropdown-item-icon {
	color: var(--night-muted);
}
html[data-hs-theme="dark"] .dropdown-menu .dropdown-item:not(.disabled, :disabled),
html[data-hs-theme="dark"] .ts-dropdown .option,
html[data-hs-theme="dark"] .ts-wrapper .ts-control,
html[data-hs-theme="dark"] .ts-wrapper .ts-control input {
	color: var(--night-text);
}
html[data-hs-theme="dark"] .dropdown-menu .dropdown-item:not(.disabled, :disabled):is(:hover, :focus, :active, .active),
html[data-hs-theme="dark"] .ts-dropdown .option.active,
html[data-hs-theme="dark"] .ts-dropdown .option.selected {
	background-color: var(--night-hover);
	color: var(--night-text);
}
html[data-hs-theme="dark"] .ts-wrapper .ts-control,
html[data-hs-theme="dark"] .form-select {
	background-color: var(--night-surface);
	border-color: var(--night-border);
	color: var(--night-text);
}
html[data-hs-theme="dark"] .ts-control input::placeholder,
html[data-hs-theme="dark"] .ts-dropdown .no-results {
	color: var(--night-muted);
	opacity: 1;
}

html[data-hs-theme="dark"] .apexcharts-xaxis-label,
html[data-hs-theme="dark"] .apexcharts-yaxis-label {
	fill: var(--night-muted);
}
html[data-hs-theme="dark"] .apexcharts-legend-text {
	color: var(--night-text) !important;
}
html[data-hs-theme="dark"] .apexcharts-tooltip.apexcharts-theme-dark {
	background: var(--night-surface);
	border-color: var(--night-border);
	color: var(--night-text);
}
</style>
{/literal}
