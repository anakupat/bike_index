class BikeDecorator < ApplicationDecorator
  delegate_all

  def should_show_other_bikes
    object.current_owner_exists and object.owner.show_bikes
  end

  def show_other_bikes
    return nil unless should_show_other_bikes
    html = "<a href='/users/#{object.owner.username}'>View user's other bikes</a>"
    html.html_safe
  end

  def bike_show_twitter_and_website
    return nil unless object.current_owner_exists
    user = object.owner
    show_twitter_and_website(user)
  end

  def title
    t = ""
    t += "#{object.year} " if object.year.present?
    t += "#{object.frame_model} by " if object.frame_model.present?
    h.content_tag(:span, t) + h.content_tag(:strong, object.mnfg_name)
  end

  def title_u
    t = ""
    t += "#{object.year} " if object.year.present?
    t += h.content_tag(:strong, object.mnfg_name)
    t += Rack::Utils.escape_html(" #{object.frame_model}") if object.frame_model.present?
    t.html_safe
  end

  def stolen_string
    return nil unless object.stolen and object.current_stolen_record.present?
    s = "Stolen "
    s += "#{object.current_stolen_record.date_stolen.strftime("%m-%d-%Y")}. " if object.current_stolen_record.date_stolen.present?
    s += "from #{object.current_stolen_record.address}. " if object.current_stolen_record.address.present?
    s
  end

  def phoneable_by(user = nil)
    return nil unless object.current_stolen_record.present?
    return true if object.current_stolen_record.phone_for_everyone
    if user.present?
      return true if user.superuser
      return true if object.current_stolen_record.phone_for_shops and user.has_shop_membership?
      return true if object.current_stolen_record.phone_for_police and user.has_police_membership?
      true if object.current_stolen_record.phone_for_users      
    end
  end

  def tire_width(position)
    return "narrow" if object.send("#{position}_tire_narrow")
    "wide"
  end

  def size_display
    return nil unless object.frame_size
    if object.frame_size_unit == "ordinal"
      "#{object.frame_size.upcase}"
    else
      "#{object.frame_size} #{object.frame_size_unit}"
    end
  end

  def list_link_url(target = nil)
    if target == 'edit'
      "/bikes/#{object.id}/edit"
    else
      h.bike_path(object)
    end
  end

  def thumb_image
    if object.thumb_path
      h.image_tag(object.thumb_path, alt: title_string)
    elsif object.stock_photo_url.present?
      small = object.stock_photo_url.split('/')
      ext = "/small_" + small.pop
      h.image_tag(small.join('/') + ext, alt: title_string)
    else
      # h.image_tag("bike_photo_placeholder.png", alt: title) + h.content_tag(:span, "no image")
    end
  end

  def revised_thumb_image
    if object.thumb_path
      h.image_tag(object.thumb_path, alt: title_string)
    elsif object.stock_photo_url.present?
      small = object.stock_photo_url.split('/')
      ext = "/small_" + small.pop
      h.image_tag(small.join('/') + ext, alt: title_string)
    else
      h.image_tag('revised/bike_photo_placeholder.svg', alt: title, title: 'No image', class: 'no-image')
    end
  end

  def list_image(target = nil)
    h.content_tag :div, class: "blist-image-holder" do 
      h.link_to(list_link_url(target)) do 
        thumb_image
      end
    end
  end

  def serial_display
    return "Hidden" if object.recovered
    if object.serial.match('absent')
      object.made_without_serial ? 'Has no serial' : 'Unknown'
    else
      object.serial
    end
  end

end
