-- Seed sample notes data
INSERT INTO comprehensive_notes (id, title, topic, level, content, word_count, reading_time_minutes, created_at) VALUES 
(gen_random_uuid(), 'Indian Constitution - Overview', 'Polity', 'basic', 
'The Indian Constitution is the supreme law of India. Key features include:

- Written Constitution: Longest in the world
- Federal System with Unitary Bias
- Parliamentary Form of Government
- Fundamental Rights under Part III
- Directive Principles under Part IV
- Independent Judiciary
- Single Citizenship
- Universal Adult Franchise
- Secular State

UPSC Relevance: Frequently asked in both Prelims and Mains.', 
100, 2, NOW()),

(gen_random_uuid(), 'Indian Economy - Five Year Plans', 'Economy', 'intermediate',
'Five Year Plans in India (1951-2017):

First Five Year Plan (1951-56): Focus on agriculture, dams, irrigation
Second Plan (1956-61): Heavy industries, Mahalanobis Model
Third Plan (1961-66): Agriculture and industrial development
Fourth Plan (1969-74): Growth with stability
Fifth Plan (1974-79): Poverty eradication

Key Points for UPSC:
- NITI Aayog replaced Planning Commission in 2015
- Now replaced by 15-year vision, 7-year strategy, 3-year action plan',
120, 2, NOW()),

(gen_random_uuid(), 'Indian Geography - Monsoon System', 'Geography', 'basic',
'The Indian Monsoon System:

Southwest Monsoon (June-September):
- Brings 75% of annual rainfall
- Enters through Kerala
- Arabian Sea and Bay of Bengal branches

Northeast Monsoon (October-December):
- Also called retreating monsoon
- Important for Tamil Nadu

Factors affecting monsoon:
- Differential heating of land and sea
- ITCZ shift
- Jet streams
- El Nino and La Nina',
90, 2, NOW());

-- Seed sample PYQ data  
INSERT INTO pyq_questions (id, year, exam_type, paper, subject, question_text, question_type, marks, source, created_at) VALUES
(gen_random_uuid(), 2023, 'prelims', 'GS1', 'Polity', 
'Which of the following is NOT a Fundamental Right under the Indian Constitution?', 
'mcq', 2, 'UPSC Official', NOW()),

(gen_random_uuid(), 2023, 'prelims', 'GS1', 'Economy',
'Consider the following statements about GST Council. Which is correct?',
'mcq', 2, 'UPSC Official', NOW()),

(gen_random_uuid(), 2022, 'mains', 'GS2', 'Polity',
'Discuss the role of Governor in state administration. Has it evolved over time?',
'descriptive', 15, 'UPSC Official', NOW());
