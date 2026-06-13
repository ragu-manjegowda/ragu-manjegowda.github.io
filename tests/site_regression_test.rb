require 'minitest/autorun'
require 'uri'
require 'yaml'

class SiteRegressionTest < Minitest::Test
	ROOT = File.expand_path('..', __dir__)
	SITE = File.join(ROOT, '_site')

	def read_site(path)
		File.read(File.join(SITE, path))
	end

	def read_root(path)
		File.read(File.join(ROOT, path))
	end

	def test_feed_and_robots_are_generated
		assert_path_exists File.join(SITE, 'feed.xml')
		assert_includes read_site('feed.xml'), '<feed'
		assert_includes read_site('robots.txt'), "Sitemap: https://ragu-manjegowda.github.io/sitemap.xml\n"
	end

	def test_jekyll_excludes_ci_dependency_and_tooling_directories
		config = YAML.load_file(File.join(ROOT, '_config.yml'))
		excludes = config.fetch('exclude')

		%w[.bundle .github node_modules scripts tests vendor vendor/bundle].each do |path|
			assert_includes excludes, path
			refute_path_exists File.join(SITE, path), "#{path} should not be copied into _site"
		end
	end

	def test_sitemap_has_single_homepage_and_featured_priority_logic_rendered
		sitemap = read_site('sitemap.xml')
		assert_equal 1, sitemap.scan(%r{<loc>https://ragu-manjegowda.github.io/</loc>}).length
		refute_includes sitemap, 'featured'
		refute_includes sitemap, 'elsif'
	end

	def test_generated_pages_do_not_advertise_localhost_or_insecure_page_assets
		bad = Dir.glob(File.join(SITE, '**/*.html')).flat_map do |path|
			File.read(path).scan(/(?:href|src)="(http:\/\/[^"]+)"/).flatten.reject do |url|
				URI(url).host == 'localhost' || URI(url).host == '0.0.0.0'
			end.map { |url| "#{path.sub(ROOT + '/', '')}: #{url}" }
		end

		assert_empty bad
	end

	def test_contact_form_keeps_accessible_labels_and_existing_social_image
		contact = read_site('contact/index.html')
		%w[name email subject textbody].each do |id|
			assert_match %r{<label class="visually-hidden" for="#{id}">}, contact
			assert_match %r{id="#{id}"}, contact
		end

		assert_includes contact, 'images/contact.jpg'
		refute_includes contact, 'contact.png'
	end

	def test_menu_aria_markup_and_runtime_state_sync_are_present
		index = read_site('index.html')
		main_js = read_site('js/main.js')

		assert_match %r{class="menuToggle"[^>]*aria-controls="menu"[^>]*aria-expanded="false"}, index
		assert_match %r{id="menu"[^>]*aria-hidden="true"}, index
		assert_includes main_js, "$menuToggle.attr('aria-expanded', isVisible ? 'true' : 'false')"
		assert_includes main_js, "$menu.attr('aria-hidden', isVisible ? 'false' : 'true')"
	end

	def test_blog_archive_titles_are_allowed_to_wrap_on_mobile
		blog = read_site('blog/index.html')

		assert_includes blog, 'class="blog-archive"'
		refute_match %r{<a\b[^>]*style="[^"]*white-space:\s*nowrap}i, blog
	end

	def test_external_link_normalizer_is_shipped_for_markdown_links
		main_js = read_site('js/main.js')

		assert_includes main_js, "a[href^=\"http://\"], a[href^=\"https://\"]"
		assert_includes main_js, 'window.location.origin'
		assert_includes main_js, ".attr('target', '_blank')"
		assert_includes main_js, "addRel('noopener')"
		assert_includes main_js, "addRel('noreferrer')"
	end

	def test_static_new_tab_links_are_protected
		bad = Dir.glob(File.join(ROOT, '{_includes,_pages,_posts}/**/*.{html,md}')).flat_map do |path|
			File.read(path).scan(/<a\b[^>]*target="_blank"[^>]*>/m).flatten.reject do |anchor|
				anchor.match?(/rel="[^"]*\bnoopener\b[^"]*\bnoreferrer\b[^"]*"/) ||
					anchor.match?(/rel="[^"]*\bnoreferrer\b[^"]*\bnoopener\b[^"]*"/)
			end.map { |anchor| "#{path.sub(ROOT + '/', '')}: #{anchor}" }
		end

		assert_empty bad
	end
end
