require 'minitest/autorun'
require 'nokogiri'
require 'uri'

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

	def root_variables(stylesheet = CSS)
		stylesheet.match(/:root\s*\{([^}]+)\}/m)[1].scan(/(--[\w-]+):\s*([^;]+);/).to_h
	end

	def dark_variables(stylesheet = CSS)
		stylesheet.match(/@media \(prefers-color-scheme: dark\)\s*\{\s*:root\s*\{([^}]+)\}/m)[1].scan(/(--[\w-]+):\s*([^;]+);/).to_h
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

	def test_landing_keeps_its_original_photograph_and_light_foreground
		home = Nokogiri::HTML(File.read(File.join(ROOT, '_site/index.html')))
		assert home.at_css('body.landing #banner')
		refute_includes home.css('head style').text, '--banner-image'
		assert_path_exists File.join(ROOT, '_site/images/banner.jpg')
		['body.landing #page-wrapper', 'body.is-mobile.landing #banner', 'body.is-mobile.landing .wrapper.style4'].each do |selector|
			assert blocks.any? { |selectors, css| selectors.include?(selector) && css.include?('/images/banner.jpg') }, selector
		end
		['#banner h1', '#banner p', '#banner .more', '#header.alt nav>ul>li>a.menuToggle',
		 '.spotlight h2', '.spotlight p', '#cta header h2', '#cta header p'].each do |selector|
			assert_declaration "body.landing #{selector}", 'color', '#eee8d5'
		end
	end

	def test_theme_panel_text_contrast_is_safe_in_both_color_schemes
		assert_operator contrast(root_variables['--theme-fg-bold'], root_variables['--theme-group-bg']), :>=, 4.5
		assert_operator contrast(dark_variables['--theme-fg-bold'], dark_variables['--theme-group-bg']), :>=, 4.5
		assert_operator contrast('#eee8d5', '#002b36'), :>=, 4.5
	end

	def test_portfolio_pages_keep_bitmap_previews_and_interior_pages_use_svg_banners
		assert_any_declaration '#main>header', 'background-image', 'var(--banner-image)'
		site = File.join(ROOT, '_site')
		paths = Dir.glob(File.join(site, '**/*.html')).reject { |path| path.start_with?(File.join(site, 'assets/')) }
		banners = []
		paths.each do |path|
			page = Nokogiri::HTML(File.read(path))
			next unless page.at_css('#page-wrapper')

			social = page.at_css('meta[property="og:image"]')['content']
			assert_match(/\.(?:png|jpe?g)\z/i, social, path)
			assert_path_exists File.join(site, URI.parse(social).path)
			assert_equal social, page.at_css('meta[name="twitter:image"]')['content']
			next if path == File.join(site, 'index.html')

			assert page.at_css('#main > header'), path
			url = page.css('head style').text[/--banner-image:\s*url\("([^"]+\.svg)"\)/, 1]
			refute_nil url, path
			assert_path_exists File.join(site, url)
			banners << url
		end
		assert_includes banners, '/images/android-tv-remote-banner.svg'
		assert_equal Dir.glob(File.join(site, 'images/banners/*.svg')).sort,
			banners.uniq.grep(%r{/images/banners/}).map { |url| File.join(site, url) }.sort
	end

	def test_standalone_banners_have_resolved_artwork_and_contrast_in_both_schemes
		assert_any_declaration '#main>header h1', 'color', 'var(--theme-fg-bold)'
		Dir.glob(File.join(ROOT, '_site/images/{banners/*.svg,android-tv-remote-banner.svg}')).each do |path|
			banner = Nokogiri::XML(File.read(path)) { |config| config.strict.nonet }
			banner.remove_namespaces!
			assert_equal 'svg', banner.root.name, path
			refute_empty banner.at_xpath('/svg/title').text, path
			%w[left right].each do |side|
				assert banner.at_xpath("//g[@id='#{side}']/*"), path
				assert banner.at_xpath("/svg/svg/use[@href='##{side}']"), path
			end
			banner.xpath('//use').each do |use|
				assert banner.at_xpath("//*[@id='#{use['href'].delete_prefix('#')}']"), path
			end
			style = banner.at_xpath('/svg/style').text
			[[root_variables, root_variables(style)], [dark_variables, dark_variables(style)]].each do |site, art|
				%w[--wall --wall-edge].each do |background|
					assert_operator contrast(site.fetch('--theme-fg-bold'), art.fetch(background)), :>=, 4.5, path
				end
				assert_operator contrast(art.fetch('--ink'), art.fetch('--key-face')), :>=, 4.5, path
			end
		end
	end

	def test_remote_demo_uses_system_colors_before_javascript_runs
		demo = Nokogiri::HTML(File.read(File.join(ROOT, '_site/projects/android-tv-remote/demo/index.html')))
		assert_equal 'light dark', demo.at_css('meta[name="color-scheme"]')['content']
		style = demo.at_css('style').text
		assert_match(/:root\s*\{\s*color-scheme:\s*light dark;/, style)
		assert_match(/--card:\s*light-dark\(#fdf6e3, #002b36\)/, style)
		assert demo.at_css('button#theme')
	end

	def test_post_content_surfaces_have_solarized_contrast_tokens
		assert_any_declaration '.wrapper.style5 pre code', 'background-color', 'var(--theme-code-bg)'
		assert_declaration 'pre code', 'color', 'var(--theme-code-fg)'
		assert_declaration '.wrapper.style5 p code', 'background-color', 'var(--theme-inline-code-bg)'
		assert_declaration '.wrapper.style5 kbd', 'background-color', 'var(--theme-kbd-bg)'
		assert_declaration '.wrapper.style5 .layer-caption', 'color', 'var(--theme-fg-light)'
	end

	def test_about_portrait_is_viewport_friendly
		assert_declaration '.wrapper.style5 .about-portrait', 'max-width', '16rem'
		assert_declaration '.wrapper.style5 .about-portrait', 'margin-left', 'auto'
		assert_declaration '.wrapper.style5 .about-portrait', 'margin-right', 'auto'
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
