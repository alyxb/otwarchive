namespace :Tag do
  desc "Reset common taggings - slow"
  task(:reset_common => :environment) do
    ThinkingSphinx.deltas_enabled=false
    Work.find(:all).each do |w|
      print "." if w.id.modulo(100) == 0; STDOUT.flush
      #w.update_common_tags
    end
    puts "Common tags reset."
    ThinkingSphinx.deltas_enabled=true
  end
  desc "Reset tag count"
  task(:reset_count => :environment) do
    Tag.find(:all).each do |t|
      Tag.update_counters t.id, :taggings_count => -t.taggings_count
      Tag.update_counters t.id, :taggings_count => t.taggings.length
    end
    puts "Tag count reset."
  end
  desc "Update pairing has_characters"
  task(:update_has_characters => :environment) do
    Pairing.all.each do |pairing|
      pairing.update_attribute(:has_characters, true) unless pairing.characters.blank?
    end
  end
  desc "Delete unused tags"
  task(:delete_unused => :environment) do
    deleted_names = []
    Tag.find(:all, :conditions => {:canonical => false, :merger_id => nil, :taggings_count => 0}).each do |t|
      if t.taggings.count == 0 && t.child_taggings.count == 0
        deleted_names << t.name
        t.destroy
      end
    end
    unless deleted_names.blank?
      puts "The following unused tags were deleted:"
      puts deleted_names.join(", ")
    end
  end
  desc "Clean up orphaned taggings"
  task(:clean_up_taggings => :environment) do
    Tagging.find_each {|t| t.destroy if t.taggable.nil?}  
  end
  desc "Reset filter taggings"
  task(:reset_filters => :environment) do
    FilterTagging.delete_all
    FilterTagging.build_from_taggings
  end
  desc "Reset filter counts"
  task(:reset_filter_counts => :environment) do
    FilterCount.set_all
  end
  desc "Reset filter counts from date"
  task(:unsuspend_filter_counts => :environment) do
    if AdminSetting.first && AdminSetting.first.suspend_filter_counts_at
      FilterTagging.update_filter_counts_since(AdminSetting.first.suspend_filter_counts_at)
    end    
  end
end
