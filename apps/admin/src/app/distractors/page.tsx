'use client';

// Story 8.7 AC 10: Admin Review Interface for MCQ Distractors
// Allows admins to review, edit, and improve low-quality distractors

import { useState, useEffect } from 'react';
import { getSupabaseBrowserClient } from '@/lib/supabase/client';

interface QuestionForReview {
  question_id: string;
  question_source: string;
  avg_quality_score: number;
  total_attempts: number;
  correct_rate: number;
  question_text?: string;
  options?: QuestionOption[];
}

interface QuestionOption {
  id: string;
  option_letter: string;
  option_text: string;
  is_correct: boolean;
  explanation: string;
  distractor_type: string | null;
  quality_score: number;
  times_selected: number;
  times_shown: number;
  is_reviewed: boolean;
}

export default function DistractorReviewPage() {
  const [questions, setQuestions] = useState<QuestionForReview[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedQuestion, setSelectedQuestion] = useState<QuestionForReview | null>(null);
  const [editingOption, setEditingOption] = useState<string | null>(null);
  const [editText, setEditText] = useState('');
  const [editExplanation, setEditExplanation] = useState('');
  const [saving, setSaving] = useState(false);
  const [regenerating, setRegenerating] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const supabase = getSupabaseBrowserClient();

  useEffect(() => {
    fetchQuestionsNeedingReview();
  }, []);

  const fetchQuestionsNeedingReview = async () => {
    setLoading(true);
    try {
      // Call the RPC function to get questions needing review
      const { data, error } = await (supabase as any).rpc('get_questions_needing_review', {
        p_min_attempts: 10
      });

      if (error) {
        console.error('Failed to fetch questions:', error);
        // Fallback to direct query
        const { data: fallbackData } = await supabase
          .from('question_options')
          .select('question_id, question_source, quality_score')
          .lt('quality_score', 0.5)
          .eq('is_reviewed', false)
          .limit(50);
        
        if (fallbackData) {
          const grouped = fallbackData.reduce((acc: any, curr: any) => {
            const key = `${curr.question_id}-${curr.question_source}`;
            if (!acc[key]) {
              acc[key] = {
                question_id: curr.question_id,
                question_source: curr.question_source,
                avg_quality_score: curr.quality_score,
                total_attempts: 0,
                correct_rate: 0
              };
            }
            return acc;
          }, {});
          setQuestions(Object.values(grouped));
        }
      } else {
        setQuestions(data || []);
      }
    } catch (err) {
      console.error('Error fetching questions:', err);
    } finally {
      setLoading(false);
    }
  };

  const loadQuestionDetails = async (question: QuestionForReview) => {
    try {
      // Fetch question text
      const { data: questionData } = await supabase
        .from(question.question_source === 'generated' ? 'generated_questions' : 'pyq_questions')
        .select('question_text')
        .eq('id', question.question_id)
        .single();

      // Fetch options
      const { data: optionsData } = await supabase
        .from('question_options')
        .select('*')
        .eq('question_id', question.question_id)
        .eq('question_source', question.question_source)
        .order('option_letter');

      setSelectedQuestion({
        ...question,
        question_text: (questionData as any)?.question_text || 'Question text not available',
        options: optionsData as QuestionOption[] || []
      });
    } catch (err) {
      console.error('Error loading question details:', err);
    }
  };

  const startEdit = (option: QuestionOption) => {
    setEditingOption(option.id);
    setEditText(option.option_text);
    setEditExplanation(option.explanation || '');
  };

  const cancelEdit = () => {
    setEditingOption(null);
    setEditText('');
    setEditExplanation('');
  };

  const saveEdit = async (optionId: string) => {
    if (!editText.trim()) {
      setError('Option text cannot be empty');
      return;
    }

    setSaving(true);
    setError('');
    setSuccess('');

    try {
      const { data: { user } } = await supabase.auth.getUser();

      const { error } = await supabase
        .from('question_options')
        .update({
          option_text: editText,
          explanation: editExplanation,
          is_reviewed: true,
          reviewed_by: user?.id,
          reviewed_at: new Date().toISOString(),
          quality_score: 0.80 // Manual review gets quality boost
        })
        .eq('id', optionId);

      if (error) throw error;

      // Refresh the question details
      if (selectedQuestion) {
        await loadQuestionDetails(selectedQuestion);
      }

      setSuccess('Option updated successfully');
      cancelEdit();
    } catch (err: any) {
      setError(err.message || 'Failed to save changes');
    } finally {
      setSaving(false);
    }
  };

  const regenerateDistractors = async () => {
    if (!selectedQuestion) return;

    setRegenerating(true);
    setError('');
    setSuccess('');

    try {
      const correctOption = selectedQuestion.options?.find(o => o.is_correct);
      
      const { data: { session } } = await supabase.auth.getSession();
      
      const response = await fetch('/api/questions/distractors', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${session?.access_token}`
        },
        body: JSON.stringify({
          question_text: selectedQuestion.question_text,
          correct_answer: correctOption?.option_text || '',
          question_id: selectedQuestion.question_id,
          question_source: selectedQuestion.question_source
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Regeneration failed');
      }

      setSuccess('Distractors regenerated successfully');
      await loadQuestionDetails(selectedQuestion);
    } catch (err: any) {
      setError(err.message || 'Failed to regenerate distractors');
    } finally {
      setRegenerating(false);
    }
  };

  const markAsReviewed = async () => {
    if (!selectedQuestion?.options) return;

    setSaving(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();

      const { error } = await supabase
        .from('question_options')
        .update({
          is_reviewed: true,
          reviewed_by: user?.id,
          reviewed_at: new Date().toISOString()
        })
        .eq('question_id', selectedQuestion.question_id)
        .eq('question_source', selectedQuestion.question_source);

      if (error) throw error;

      setSuccess('All options marked as reviewed');
      await fetchQuestionsNeedingReview();
      setSelectedQuestion(null);
    } catch (err: any) {
      setError(err.message || 'Failed to mark as reviewed');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="max-w-6xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-2">MCQ Distractor Review</h1>
      <p className="text-gray-600 mb-8">Review and improve low-quality distractors</p>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {error}
        </div>
      )}

      {success && (
        <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg text-green-700">
          {success}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Questions List */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-lg font-bold mb-4">Questions Needing Review</h2>
            
            {loading ? (
              <div className="text-center py-8">
                <div className="w-8 h-8 border-2 border-blue-600 border-t-transparent rounded-full animate-spin mx-auto"></div>
              </div>
            ) : questions.length === 0 ? (
              <p className="text-gray-600 text-center py-8">No questions need review!</p>
            ) : (
              <div className="space-y-2 max-h-96 overflow-y-auto">
                {questions.map((q, idx) => (
                  <button
                    key={`${q.question_id}-${idx}`}
                    onClick={() => loadQuestionDetails(q)}
                    className={`w-full text-left p-3 rounded-lg border transition ${
                      selectedQuestion?.question_id === q.question_id
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-gray-200 hover:bg-gray-50'
                    }`}
                  >
                    <div className="flex justify-between items-center mb-1">
                      <span className="text-sm font-medium truncate">
                        Question #{idx + 1}
                      </span>
                      <span className={`text-xs px-2 py-1 rounded ${
                        q.avg_quality_score < 0.4 ? 'bg-red-100 text-red-700' :
                        q.avg_quality_score < 0.6 ? 'bg-yellow-100 text-yellow-700' :
                        'bg-green-100 text-green-700'
                      }`}>
                        {(q.avg_quality_score * 100).toFixed(0)}%
                      </span>
                    </div>
                    <div className="text-xs text-gray-500">
                      {q.total_attempts} attempts • {(q.correct_rate * 100).toFixed(0)}% correct
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Question Details */}
        <div className="lg:col-span-2">
          {selectedQuestion ? (
            <div className="bg-white rounded-xl shadow-lg p-6">
              <div className="flex justify-between items-start mb-6">
                <h2 className="text-lg font-bold">Question Details</h2>
                <div className="flex space-x-2">
                  <button
                    onClick={regenerateDistractors}
                    disabled={regenerating}
                    className="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 disabled:bg-gray-400 flex items-center space-x-2"
                  >
                    {regenerating ? (
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    ) : (
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                      </svg>
                    )}
                    <span>Regenerate</span>
                  </button>
                  <button
                    onClick={markAsReviewed}
                    disabled={saving}
                    className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400"
                  >
                    Mark Reviewed
                  </button>
                </div>
              </div>

              <div className="mb-6 p-4 bg-gray-50 rounded-lg">
                <p className="font-medium">{selectedQuestion.question_text}</p>
              </div>

              <h3 className="font-medium mb-4">Options</h3>
              <div className="space-y-4">
                {selectedQuestion.options?.map(option => (
                  <div
                    key={option.id}
                    className={`p-4 rounded-lg border ${
                      option.is_correct ? 'border-green-300 bg-green-50' : 'border-gray-200'
                    }`}
                  >
                    {editingOption === option.id ? (
                      <div className="space-y-3">
                        <input
                          type="text"
                          value={editText}
                          onChange={(e) => setEditText(e.target.value)}
                          className="w-full border rounded px-3 py-2"
                          placeholder="Option text"
                        />
                        <textarea
                          value={editExplanation}
                          onChange={(e) => setEditExplanation(e.target.value)}
                          className="w-full border rounded px-3 py-2"
                          rows={2}
                          placeholder="Explanation"
                        />
                        <div className="flex space-x-2">
                          <button
                            onClick={() => saveEdit(option.id)}
                            disabled={saving}
                            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400"
                          >
                            {saving ? 'Saving...' : 'Save'}
                          </button>
                          <button
                            onClick={cancelEdit}
                            className="px-4 py-2 border rounded hover:bg-gray-50"
                          >
                            Cancel
                          </button>
                        </div>
                      </div>
                    ) : (
                      <>
                        <div className="flex justify-between items-start mb-2">
                          <div className="flex items-center space-x-2">
                            <span className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                              option.is_correct ? 'bg-green-500 text-white' : 'bg-gray-200'
                            }`}>
                              {option.option_letter}
                            </span>
                            <span className="font-medium">{option.option_text}</span>
                          </div>
                          {!option.is_correct && (
                            <button
                              onClick={() => startEdit(option)}
                              className="text-blue-600 hover:text-blue-800 text-sm"
                            >
                              Edit
                            </button>
                          )}
                        </div>
                        
                        {option.explanation && (
                          <p className="text-sm text-gray-600 ml-10 mb-2">{option.explanation}</p>
                        )}
                        
                        <div className="flex space-x-4 ml-10 text-xs text-gray-500">
                          <span>Quality: {(option.quality_score * 100).toFixed(0)}%</span>
                          <span>Selected: {option.times_selected}/{option.times_shown}</span>
                          {option.distractor_type && (
                            <span className="px-2 py-0.5 bg-gray-100 rounded">{option.distractor_type}</span>
                          )}
                          {option.is_reviewed && (
                            <span className="text-green-600">✓ Reviewed</span>
                          )}
                        </div>
                      </>
                    )}
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-xl shadow-lg p-6 flex items-center justify-center h-64">
              <p className="text-gray-500">Select a question to review</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
