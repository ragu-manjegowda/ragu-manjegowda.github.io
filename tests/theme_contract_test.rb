require 'minitest/autorun'

class ThemeContractTest < Minitest::Test
	ROOT = File.expand_path('..', __dir__)
	CSS = File.read(File.join(ROOT, '_site/css/main.css'))

	def blocks
		@blocks ||= CSS.scan(/([^{}]+)\{([^{}]+)\}/m).map do |selectors, declarations|
			[selectors.split(',').map(&:strip), declarations]
		end
	end

	def declarations_for(selector)
		block = blocks.reverse.find { |selectors, _| selectors.include?(selector) }
		assert block, "Missing CSS block for #{selector}"
		block.last
	end

	def assert_declaration(selector, property, value)
		assert_match(/#{Regexp.escape(property)}:\s*#{Regexp.escape(value)}\s*;?/, declarations_for(selector))
	end

	def assert_any_declaration(selector, property, value)
		matching = blocks.select { |selectors, _| selectors.include?(selector) }.map(&:last)
		assert matching.any?, "Missing CSS block for #{selector}"
		assert matching.any? { |declarations| declarations.match?(/#{Regexp.escape(property)}:\s*#{Regexp.escape(value)}\s*;?/) },
			"Expected #{selector} to declare #{property}: #{value}"
	end

	def root_variables
		@root_variables ||= CSS.match(/:root\s*\{([^}]+)\}/m)[1].scan(/(--[\w-]+):\s*([^;]+);/).to_h
	end

	def dark_variables
		@dark_variables ||= CSS.match(/@media \(prefers-color-scheme: dark\)\s*\{\s*:root\s*\{([^}]+)\}/m)[1].scan(/(--[\w-]+):\s*([^;]+);/).to_h
	end

	def rgb(hex)
		hex.delete_prefix('#').scan(/../).map { |part| part.to_i(16) }
	end

	def luminance(hex)
		rgb(hex).map do |channel|
			value = channel / 255.0
			value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
		end.then { |r, g, b| 0.2126 * r + 0.7152 * g + 0.0722 * b }
	end

	def contrast(foreground, background)
		dark, light = [luminance(foreground), luminance(background)].minmax
		(light + 0.05) / (dark + 0.05)
	end

	def test_solarized_light_and_dark_tokens_exist
		assert_equal '#fdf6e3', root_variables['--theme-bg']
		assert_equal '#073642', root_variables['--theme-fg-bold']
		assert_equal '#eee8d5', root_variables['--theme-group-bg']
		assert_equal '#002b36', dark_variables['--theme-bg']
		assert_equal '#eee8d5', dark_variables['--theme-fg-bold']
		assert_equal '#073642', dark_variables['--theme-group-bg']
	end

	def test_fixed_light_foreground_is_used_for_image_backed_landing_surfaces
		assert_declaration 'body.landing #banner h1', 'color', '#eee8d5'
		assert_declaration 'body.landing #banner p', 'color', '#eee8d5'
		assert_declaration 'body.landing #header.alt nav>ul>li>a.menuToggle', 'color', '#eee8d5'
		assert_declaration 'body.landing .spotlight h2', 'color', '#eee8d5'
		assert_declaration 'body.landing .spotlight p', 'color', '#eee8d5'
		assert_declaration 'body.landing #cta header h2', 'color', '#eee8d5'
		assert_declaration 'body.landing #cta header p', 'color', '#eee8d5'
	end

	def test_theme_panel_text_contrast_is_safe_in_both_color_schemes
		assert_operator contrast(root_variables['--theme-fg-bold'], root_variables['--theme-group-bg']), :>=, 4.5
		assert_operator contrast(dark_variables['--theme-fg-bold'], dark_variables['--theme-group-bg']), :>=, 4.5
		assert_operator contrast('#eee8d5', '#002b36'), :>=, 4.5
	end

	def test_post_content_surfaces_have_solarized_contrast_tokens
		assert_any_declaration '.wrapper.style5 pre code', 'background-color', 'var(--theme-code-bg)'
		assert_declaration 'pre code', 'color', 'var(--theme-code-fg)'
		assert_declaration '.wrapper.style5 p code', 'background-color', 'var(--theme-inline-code-bg)'
		assert_declaration '.wrapper.style5 kbd', 'background-color', 'var(--theme-kbd-bg)'
		assert_declaration '.wrapper.style5 .layer-caption', 'color', 'var(--theme-fg-light)'
	end

	def test_blog_archive_titles_wrap_within_mobile_viewport
		assert_any_declaration '.wrapper.style5 .blog-archive', 'max-width', '100%'
		assert_any_declaration '.wrapper.style5 .blog-archive', 'overflow-wrap', 'anywhere'
		assert_any_declaration '.wrapper.style5 .blog-archive a', 'overflow-wrap', 'anywhere'
		assert_any_declaration '.wrapper.style5 .blog-archive a', 'word-break', 'break-word'
		assert_any_declaration '.wrapper.style5 .blog-archive code', 'white-space', 'nowrap'
	end

	def test_contact_fields_and_project_tags_use_theme_tokens
		assert_declaration '.wrapper.style5 input[type="text"]', 'background-color', 'var(--theme-field-bg)'
		assert_declaration '.wrapper.style5 input[type="email"]', 'color', 'var(--theme-field-fg)'
		assert_declaration '.wrapper.style5 .techlist li', 'background-color', 'var(--theme-tag-bg)'
		assert_declaration '.wrapper.style5 .techlist li', 'color', 'var(--theme-tag-fg)'
	end
end
