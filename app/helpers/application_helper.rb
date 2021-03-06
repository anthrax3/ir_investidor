module ApplicationHelper
  APP_VERSION = `git log --pretty=%H`.split("\n").first

  # Build a breadcrumb hash
  URLS = Rails.application.routes.url_helpers
  BREADCRUMB = {
    'dashboard#index' => [{ content: 'Início', active: true }],
    'dashboard#account' => [{ content: 'Configurações' },
                            { content: 'Minha conta', active: true}],
    'dashboard#update_account' => [{ content: 'Configurações' },
                                   { content: 'Minha conta', active: true}],
    'books#index' => [{ content: 'Configurações' },
                      { content: 'Estratégias', active: true}],
    'books#new' => [{ content: 'Configurações' },
                    { content: 'Estratégias', href: URLS.books_path },
                    { content: 'Nova estratégia', active: true}],
    'user_brokers#index' => [{ content: 'Configurações' },
                             { content: 'Corretoras', active: true }],
    'user_brokers#new' => [{ content: 'Configurações' },
                           { content: 'Corretoras', href: URLS.user_brokers_path },
                           { content: 'Nova corretora', active: true}],
    'user_brokers#create' => [{ content: 'Configurações' },
                              { content: 'Corretoras', href: URLS.user_brokers_path },
                              { content: 'Nova corretora', active: true}],
    'user_brokers#edit' => [{ content: 'Configurações' },
                            { content: 'Corretoras', href: URLS.user_brokers_path },
                            { content: 'Editar corretora', active: true}],
    'user_brokers#update' => [{ content: 'Configurações' },
                              { content: 'Corretoras', href: URLS.user_brokers_path },
                              { content: 'Editar corretora', active: true}],
    'transactions#index' => [{ content: 'Investimentos' },
                             { content: 'Operações', active: true }],
    'transactions#new' => [{ content: 'Investimentos' },
                           { content: 'Operações', href: URLS.transactions_path },
                           { content: 'Nova operação', active: true}],
    'transactions#create' => [{ content: 'Investimentos' },
                              { content: 'Operações', href: URLS.transactions_path },
                              { content: 'Nova operação', active: true}],
    'transactions#edit' => [{ content: 'Investimentos' },
                            { content: 'Operações', href: URLS.transactions_path },
                            { content: 'Editar operação', active: true}],
    'transactions#update' => [{ content: 'Investimentos' },
                              { content: 'Operações', href: URLS.transactions_path },
                              { content: 'Editar operação', active: true}],
    'holdings#index' => [{ content: 'Investimentos' },
                         { content: 'Posições', active: true }],
    'portfolio#index' => [{ content: 'Investimentos' },
                          { content: 'Minha carteira', active: true }],
    'tax#index' => [{ content: 'Investimentos' },
                    { content: 'Impostos', active: true }],
  }

  def app_version
    APP_VERSION
  end

  def menu_link_to(content, controller, action, active=nil)
    if active.nil?
      # evaluate if controller and action match the current ones
      active = (controller_name == controller && action_name == action)
    end
    url = url_for(controller: controller, action: action)
    html_class = 'nav-link'
    html_class += ' active' if active
    link_to content.html_safe, url, class: html_class
  end

  def book_from_id(book_id)
    return @book_from_id[book_id] if @book_from_id
    @book_from_id = Hash[current_user.books.map { |book| [book.id, book] }]
    @book_from_id[book_id]
  end

  def user_broker_from_id(user_broker_id)
    return @user_broker_from_id[user_broker_id] if @user_broker_from_id
    @user_broker_from_id = Hash[current_user.user_brokers.map do |user_broker|
      [user_broker.id, user_broker]
    end]
    @user_broker_from_id[user_broker_id]
  end
end
