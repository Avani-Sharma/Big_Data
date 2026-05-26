import streamlit as st

# Page Settings
st.set_page_config(
    page_title="Student Registration Form",
    page_icon="🎓",
    layout="centered"
)

# Title
st.title("🎓 Student Registration Form")

st.write("Fill all details below")

# Input Fields
name = st.text_input("👤 Full Name")

address = st.text_area("🏠 Address")

course = st.selectbox(
    "📚 Select Course",
    ["BCA", "MCA", "B.Tech", "Data Science", "Data Engineering"]
)

email = st.text_input("📧 Email ID")

phone = st.text_input("📱 Phone Number")

gender = st.radio(
    "⚧ Gender",
    ["Male", "Female", "Other"]
)

dob = st.date_input("📅 Date of Birth")

# Submit Button
if st.button("Submit"):

    # Check empty fields
    if name and address and email and phone:

        # Celebration
        st.balloons()

        # Success Popup
        st.success(f"""
        🎉 Congratulations {name}!

        You are logged in successfully.
        """)

        # Show Details
        st.subheader("✅ Submitted Details")

        st.write("👤 Name:", name)
        st.write("🏠 Address:", address)
        st.write("📚 Course:", course)
        st.write("📧 Email:", email)
        st.write("📱 Phone:", phone)
        st.write("⚧ Gender:", gender)
        st.write("📅 DOB:", dob)

    else:
        st.error("⚠️ Please fill all required details")