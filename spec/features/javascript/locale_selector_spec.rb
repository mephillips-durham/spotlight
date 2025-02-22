# frozen_string_literal: true

RSpec.describe 'Locale Selector', js: true do
  let(:exhibit) { FactoryBot.create(:exhibit, published: true) }
  let!(:language_es) { FactoryBot.create(:language, exhibit: exhibit, locale: 'es', public: true) }
  let!(:language_zh) { FactoryBot.create(:language, exhibit: exhibit, locale: 'zh') }

  before { login_as user }

  before(:all) do
    # mimics setting config.i18n.fallbacks = [I18n.default_locale] in the rails environment
    I18n.fallbacks[:es] = [:es, I18n.default_locale]
  end

  context 'with an anonymous user' do
    let(:user) { FactoryBot.create(:exhibit_visitor) }

    it 'only sees public languages' do
      visit spotlight.exhibit_path(exhibit)

      expect(page).to have_css('li.dropdown', text: 'English')
      click_link 'English'

      within('.dropdown-menu', visible: true) do
        expect(page).to have_css('li', count: 1)
        expect(page).to have_css('li', text: 'Español')
      end
    end
  end

  context 'with an exhibit curator' do
    let(:user) { FactoryBot.create(:exhibit_curator, exhibit: exhibit) }

    it 'can see any saved languages' do
      visit spotlight.exhibit_path(exhibit)

      expect(page).to have_css('li.dropdown', text: 'English')
      click_link 'English'

      within('.dropdown-menu', visible: true) do
        expect(page).to have_css('li', count: 2)
        expect(page).to have_css('li', text: '中文')
        expect(page).to have_css('li', text: 'Español')
      end
    end
  end

  describe 'switching locales' do
    let(:user) { FactoryBot.create(:exhibit_visitor) }

    it 'allows the user to select the language most appropriate for them' do
      visit spotlight.exhibit_path(exhibit)

      expect(page).to have_css('input[placeholder="Search..."]')

      click_link 'English'

      within('.dropdown-menu', visible: true) do
        click_link 'Español'
      end

      expect(page).not_to have_css('input[placeholder="Search..."]')
      expect(page).to have_css('input[placeholder="Buscar..."]')
    end
  end
end
