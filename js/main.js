/*
	Spectral by HTML5 UP
	html5up.net | @n33co
	Free for personal and commercial use under the CCA 3.0 license (html5up.net/license)
*/

(function($) {

	skel
		.breakpoints({
			xlarge:	'(max-width: 1680px)',
			large:	'(max-width: 1280px)',
			medium:	'(max-width: 980px)',
			small:	'(max-width: 736px)',
			xsmall:	'(max-width: 480px)'
		});

	$(function() {

		var	$window = $(window),
			$body = $('body'),
			$wrapper = $('#page-wrapper'),
			$banner = $('#banner'),
			$header = $('#header');

		// Disable animations/transitions until the page has loaded.
			$body.addClass('is-loading');

			$window.on('load', function() {
				window.setTimeout(function() {
					$body.removeClass('is-loading');
				}, 100);
			});

		// Mobile?
			if (skel.vars.mobile)
				$body.addClass('is-mobile');
			else
				skel
					.on('-medium !medium', function() {
						$body.removeClass('is-mobile');
					})
					.on('+medium', function() {
						$body.addClass('is-mobile');
					});

		// Fix: Placeholder polyfill.
			$('form').placeholder();

		// Prioritize "important" elements on medium.
			skel.on('+medium -medium', function() {
				$.prioritize(
					'.important\\28 medium\\29',
					skel.breakpoint('medium').active
				);
			});

		// Scrolly.
			$('.scrolly')
				.scrolly({
					speed: 1500,
					offset: $header.outerHeight()
				});

			$('a[href^="http://"], a[href^="https://"]')
				.not('[href^="' + window.location.origin + '"]')
				.each(function() {
					var $link = $(this),
						rel = ($link.attr('rel') || '').split(/\s+/),
						addRel = function(value) {
							if ($.inArray(value, rel) === -1)
								rel.push(value);
						};

					addRel('noopener');
					addRel('noreferrer');

					$link
						.attr('target', '_blank')
						.attr('rel', $.trim(rel.join(' ')));
				});

		// Menu.
			var $menu = $('#menu'),
				$menuToggle = $('.menuToggle'),
				syncMenuState = function() {
					var isVisible = $body.hasClass('is-menu-visible');

					$menuToggle.attr('aria-expanded', isVisible ? 'true' : 'false');
					$menu.attr('aria-hidden', isVisible ? 'false' : 'true');
				};

			$menu
				.append('<a href="#menu" class="close" aria-label="Close menu"></a>')
				.appendTo($body)
				.panel({
					delay: 500,
					hideOnClick: true,
					hideOnSwipe: true,
					resetScroll: true,
					resetForms: true,
					side: 'right',
					target: $body,
					visibleClass: 'is-menu-visible'
				});

			$menuToggle.on('click', function() {
				window.setTimeout(syncMenuState, 0);
			});

			if ('MutationObserver' in window)
				new MutationObserver(syncMenuState).observe($body[0], { attributes: true, attributeFilter: ['class'] });

			syncMenuState();

		// Header.
			if (skel.vars.IEVersion < 9)
				$header.removeClass('alt');

			if ($banner.length > 0
			&&	$header.hasClass('alt')) {

				$window.on('resize', function() { $window.trigger('scroll'); });

				$banner.scrollex({
					bottom:		$header.outerHeight() + 1,
					terminate:	function() { $header.removeClass('alt'); },
					enter:		function() { $header.addClass('alt'); },
					leave:		function() { $header.removeClass('alt'); }
				});

			}

	});

})(jQuery);
