class Questionnaire < ActiveRecord::Base
    # for doc on why we do it this way, 
    # see http://blog.hasmanythrough.com/2007/1/15/basic-rails-association-cardinality
    has_many :questions # the collection of questions associated with this Questionnaire
    belongs_to :instructor, :class_name => "User", :foreign_key => "instructor_id" # the creator of this questionnaire
    
    has_many :assignment_questionnaire, :class_name => 'AssignmentQuestionnaire', :foreign_key => 'questionnaire_id'
    has_many :assignments, :through => :assignment_questionnaires
    
    validates_presence_of :name
    validates_numericality_of :max_question_score
    validates_numericality_of :min_question_score

    validates_presence_of :section # indicates custom rubric section 

    DEFAULT_MIN_QUESTION_SCORE = 0  # The lowest score that a reviewer can assign to any questionnaire question
    DEFAULT_MAX_QUESTION_SCORE = 5  # The highest score that a reviewer can assign to any questionnaire question
    DEFAULT_QUESTIONNAIRE_URL = "http://www.courses.ncsu.edu/csc517"
    
	def compute_weighted_score(symbol, assignment, scores)
      aq = self.assignment_questionnaire.find_by_assignment_id(assignment.id)
      if scores[symbol][:scores][:avg]
        #dont bracket and to_f the whole thing - you get a 0 in the result.. what you do is just to_f the 100 part .. to get the fractions
       
        return scores[symbol][:scores][:avg] * aq.questionnaire_weight  / 100.to_f
      else 
        return 0
      end
    end
    
    # Does this questionnaire contain true/false questions?
    def true_false_questions?
      for question in questions
        if question.TRUE_FALSE
          return true
        end
      end
      
      return false
    end
    
    def delete
      self.assignments.each{
        | assignment |
        raise "The assignment #{assignment.name} uses this questionnaire. Do you want to <A href='../assignment/delete/#{assignment.id}'>delete</A> the assignment?"
      }
      
      self.questions.each{
        | question |
          question.delete        
      }
       
     
      node = QuestionnaireNode.find_by_node_object_id(self.id)
      if node
        node.destroy
      end
                
      self.destroy      
    end
end
